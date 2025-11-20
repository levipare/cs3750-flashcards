//
//  OCRManager.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/23/25.
//

import Foundation
import UIKit
import Vision
import CoreImage
import ImageIO


public struct OCRConfig {
    public var languages: [String]                     // e.g., ["en-US"] or [] for auto-detect
    public var recognitionLevel: VNRequestTextRecognitionLevel
    public var usesLanguageCorrection: Bool
    public var maxDimension: CGFloat                   // longest edge cap for input image (px)
    public var concurrentTasks: Int
    public var minimumTextHeight: CGFloat?             // fraction of image height (e.g., 0.015)
    public var regionOfInterest: CGRect?               // normalized [0,1] ROI in Vision coords (origin at LL)
    public var customWords: [String]                   // domain hints

    public init(
        languages: [String] = [],
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        usesLanguageCorrection: Bool = true,
        maxDimension: CGFloat = 3000,
        concurrentTasks: Int = 2,
        minimumTextHeight: CGFloat? = nil,
        regionOfInterest: CGRect? = nil,
        customWords: [String] = []
    ) {
        self.languages = languages
        self.recognitionLevel = recognitionLevel
        self.usesLanguageCorrection = usesLanguageCorrection
        self.maxDimension = maxDimension
        self.concurrentTasks = max(1, concurrentTasks)
        self.minimumTextHeight = minimumTextHeight
        self.regionOfInterest = regionOfInterest
        self.customWords = customWords
    }
}

public struct OCRResult: Sendable {
    public let id: UUID
    public let text: String
    public let lines: [String]
    public init(id: UUID, text: String, lines: [String]) {
        self.id = id
        self.text = text
        self.lines = lines
    }
}

public struct OCRProgress: Sendable {
    public let total: Int
    public let completed: Int
    public let currentId: UUID
}

public final class OCRManager: @unchecked Sendable {
    public let config: OCRConfig
    private let ciContext = CIContext(options: nil)

    public init(config: OCRConfig = OCRConfig()) {
        self.config = config
    }

    // Recognize text for a single image
    public func recognize(image: UIImage, id: UUID = UUID()) async throws -> OCRResult {
        guard let cgImage = try prepareCGImage(from: image, maxDimension: config.maxDimension) else {
            throw OCRManagerError.imagePreparationFailed
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        // Build request
        let request = makeTextRequest(config: config)

        // Perform (no extra dispatch hop — already off main when awaited)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([request])

        let observations = (request.results) ?? []

        // Sort to reading order and extract top candidate strings
        let orderedLines: [String] = observations
            .sorted(by: Self.readingOrderSort(lhs:rhs:))
            .compactMap { $0.topCandidates(1).first?.string }

        let text = Self.normalize(lines: orderedLines)
        return OCRResult(id: id, text: text, lines: orderedLines)
    }

    // Recognize multiple images with bounded parallelism
    public func recognize(
        images: [(UUID, UIImage)],
        progress: @escaping (OCRProgress) -> Void
    ) async -> [UUID: OCRResult] {
        var results = [UUID: OCRResult]()
        let total = images.count
        var completed = 0
        let semaphore = AsyncSemaphore(value: config.concurrentTasks)

        await withTaskGroup(of: (UUID, OCRResult?).self) { group in
            for (id, uiImage) in images {
                await semaphore.wait()
                group.addTask { [config] in
                    defer { Task { await semaphore.signal() } }
                    do {
                        let mgr = OCRManager(config: config)
                        let res = try await mgr.recognize(image: uiImage, id: id)
                        return (id, res)
                    } catch {
                        return (id, nil)
                    }
                }
            }

            for await (id, result) in group {
                completed += 1
                if let result { results[id] = result }
                progress(OCRProgress(total: total, completed: completed, currentId: id))
            }
        }

        return results
    }
}

// MARK: - Private helpers

private extension OCRManager {

    func makeTextRequest(config: OCRConfig) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()

        // Use the best available model revision at runtime
        if let latest = VNRecognizeTextRequest.supportedRevisions.max() {
            request.revision = latest
        }

        request.recognitionLevel = config.recognitionLevel
        request.usesLanguageCorrection = config.usesLanguageCorrection

        if !config.languages.isEmpty {
            request.recognitionLanguages = config.languages
            request.automaticallyDetectsLanguage = false
        } else {
            request.automaticallyDetectsLanguage = true
        }

        if let minH = config.minimumTextHeight {
            request.minimumTextHeight = Float(minH)
        }

        if let roi = config.regionOfInterest {
            request.regionOfInterest = roi
        }

        if !config.customWords.isEmpty {
            request.customWords = config.customWords
        }

        return request
    }

    static func readingOrderSort(lhs: VNRecognizedTextObservation,
                                 rhs: VNRecognizedTextObservation) -> Bool {
        // Vision bounding boxes are in normalized image coordinates with origin at LL.
        let a = lhs.boundingBox
        let b = rhs.boundingBox
        // Sort by top-to-bottom (higher y first), then left-to-right (lower x first)
        // Because origin is LL, "top" means larger maxY.
        let aTop = a.maxY
        let bTop = b.maxY
        if abs(aTop - bTop) > 0.01 {
            return aTop > bTop
        }
        return a.minX < b.minX
    }

    static func normalize(lines: [String]) -> String {
        // Clean each line but preserve line boundaries.
        let cleaned = lines.map { line -> String in
            var s = line
            s = s.replacingOccurrences(of: "\u{00AD}", with: "")      // soft hyphen
            s = s.replacingOccurrences(of: "\u{00A0}", with: " ")     // NBSP
            // Collapse multiple spaces/tabs *within* the line
            if let regex = try? NSRegularExpression(pattern: "[ \\t]+", options: []) {
                s = regex.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: (s as NSString).length), withTemplate: " ")
            }
            return s.trimmingCharacters(in: .whitespaces)
        }
        return cleaned.joined(separator: "\n")
    }

    func prepareCGImage(from image: UIImage, maxDimension: CGFloat) throws -> CGImage? {
        // Prefer CI pipeline to scale once with good quality
        guard let cgImage = image.cgImage else { return image.cgImage }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let longest = max(width, height)

        if longest <= maxDimension {
            return cgImage
        }

        let scale = maxDimension / longest
        let newSize = CGSize(width: width * scale, height: height * scale)

        let ci = CIImage(cgImage: cgImage)
        let sx = newSize.width / width
        let sy = newSize.height / height
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: sx, y: sy))

        return ciContext.createCGImage(scaled, from: scaled.extent)
    }
}

// MARK: - Async semaphore for throttling

actor AsyncSemaphore {
    private var permits: Int
    init(value: Int) { self.permits = max(1, value) }

    func wait() async {
        while permits == 0 {
            await Task.yield()
        }
        permits -= 1
    }

    func signal() {
        permits += 1
    }
}

// MARK: - Errors

public enum OCRManagerError: Error {
    case imagePreparationFailed
}

// MARK: - Utilities

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
