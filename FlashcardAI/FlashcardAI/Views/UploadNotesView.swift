//
//  UploadImagesView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//

import PhotosUI
import SwiftUI
import UIKit
import VisionKit

struct UploadNotesView: View {
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var showScanner = false
    @State private var inputText = ""
    @State private var isExtracting = false
    @State private var progressCompleted = 0
    @State private var progressTotal = 0
    @State private var isCleaningText = false

    private let ocrManager = OCRManager()
    private let llmService = OpenRouterService(apiKey: Secrets.openRouterAPIKey)
    private let firestoreManager = FirestoreManager()
    
    var body: some View {
        ZStack {
            TextEditor(text: $inputText)
                .disabled(isExtracting || isCleaningText)
            
            if isExtracting {
                VStack(spacing: 12) {
                    ProgressView(value: progressTotal == 0 ? 0 : Double(progressCompleted) / Double(progressTotal))
                        .progressViewStyle(.linear)
                        .frame(width: 220)
                    Text("Extracting text from \(progressCompleted)/\(progressTotal) images…")
                        .font(.footnote)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if isCleaningText {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Cleaning up extracted text…")
                        .font(.footnote)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle("Upload Notes")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "photo.on.rectangle.angled")
                }.onChange(of: selectedPhotoItems) { _, newItems in
                    Task {
                        var newImages: [UIImage] = []
                        for item in selectedPhotoItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) {
                               newImages.append(image)
                           }
                        }
                        selectedPhotoItems = []
                        
                        if !newImages.isEmpty {
                            images.append(contentsOf: newImages)
                            await extractText(from: newImages)
                        }
                    }
                }
                Spacer()
                Button("Generate") {
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty)
                Spacer()
                Button("Scan", systemImage: "camera"){
                    showScanner = true
                }.labelStyle(.iconOnly)
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(
                onCancel: {
                    showScanner = false
                },
                onImages: { imgs in
                    images.append(contentsOf: imgs)
                    showScanner = false
                    Task {
                        await extractText(from: imgs)
                    }
                },
                onFailure: { error in
                    // TODO show error message
                    showScanner = false
                }
            )
        }
    }
    
    private func extractText(from newImages: [UIImage]) async {
        guard !newImages.isEmpty else { return }
        
        await MainActor.run {
            isExtracting = true
            progressCompleted = 0
            progressTotal = newImages.count
        }
        
        let pairs: [(UUID, UIImage)] = newImages.map { (UUID(), $0) }
        let dict = await ocrManager.recognize(images: pairs) { prog in
            Task { @MainActor in
                self.progressCompleted = prog.completed
                self.progressTotal = prog.total
            }
        }
        
        let ordered = pairs.compactMap { pair in dict[pair.0]?.text }
        let extractedText = ordered.joined(separator: "\n\n")
        
        await MainActor.run {
            isExtracting = false
        }
        
        // Clean up the OCR text with LLM
        guard !extractedText.isEmpty else { return }
        
        await MainActor.run {
            isCleaningText = true
        }
        
        do {
            let cleanedText = try await cleanOCRText(extractedText)
            
            await MainActor.run {
                if !inputText.isEmpty && !cleanedText.isEmpty {
                    inputText += "\n\n" + cleanedText
                } else {
                    inputText = cleanedText
                }
                isCleaningText = false
            }
        } catch {
            // If LLM cleanup fails, fall back to raw OCR text
            print("LLM cleanup failed: \(error.localizedDescription)")
            await MainActor.run {
                if !inputText.isEmpty && !extractedText.isEmpty {
                    inputText += "\n\n" + extractedText
                } else {
                    inputText = extractedText
                }
                isCleaningText = false
            }
        }
    }
    
    private func cleanOCRText(_ rawText: String) async throws -> String {
        let instructions = try await fetchCleanOCRInstructions()
        let prompt = """
        \(instructions)
        
        OCR Text to clean:
        
        \(rawText)
        """
        
        return try await llmService.sendMessage(prompt: prompt)
    }

    private func fetchCleanOCRInstructions() async throws -> String {
        do {
            let prompts = try await firestoreManager.fetchPrompts()
            if let prompt = prompts.first(where: { $0.id == "cleanOCR" }) {
                return prompt.text
            }
            throw CleanOCRPromptError.missingPrompt
        } catch {
            print("Failed to fetch prompts: \(error.localizedDescription)")
            throw error
        }
    }
}

enum CleanOCRPromptError: Error {
    case missingPrompt
}

struct DocumentScannerView: UIViewControllerRepresentable {
    let onCancel: () -> Void
    let onImages: (_ images: [UIImage]) -> Void
    let onFailure: (_ error: Error) -> Void

    func makeUIViewController(context: Context)
        -> VNDocumentCameraViewController
    {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            parent.onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.onFailure(error)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.onImages(images)
        }
    }
}
