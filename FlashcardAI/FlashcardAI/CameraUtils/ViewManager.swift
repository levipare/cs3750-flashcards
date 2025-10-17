//
//  ViewManager.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import Foundation
import CoreImage
import Observation
import SwiftUI

@Observable
final class ViewModel {
    var currentFrame: CGImage?
    var capturedImages: [UIImage] = []
    var showSuccessMessage = false
    var cameraErrorMessage: String?
    
    private let cameraManager = CameraManager()
    private var errorDismissTask: Task<Void, Never>?
    private let feedbackDuration: UInt64 = 2_000_000_000
    
    init() {
        cameraManager.start()
        Task {
            await loadFrames()
        }
    }

    deinit {
        errorDismissTask?.cancel()
    }
    
    private func loadFrames() async {
        for await frame in cameraManager.previewStream {
            await MainActor.run {
                currentFrame = frame
            }
        }
    }

    func capturePhoto() {
        guard currentFrame != nil else {
            Task { @MainActor in
                presentCameraError("Camera feed unavailable. Please try again once the camera restarts.")
            }
            return
        }
        
        Task {
            do {
                let img = try await cameraManager.capturePhoto()
                await MainActor.run {
                    capturedImages.append(img)
                    showSuccessMessage = true
                }
                
                try? await Task.sleep(nanoseconds: feedbackDuration)
                await MainActor.run {
                    showSuccessMessage = false
                }
            } catch {
                await MainActor.run {
                    let message = error.localizedDescription.isEmpty ?
                    "Unable to capture photo. Please try again." :
                    error.localizedDescription
                    presentCameraError(message)
                }
            }
        }
    }

    @MainActor
    private func presentCameraError(_ message: String) {
        cameraErrorMessage = message
        errorDismissTask?.cancel()
        let duration = feedbackDuration
        errorDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: duration)
            guard !Task.isCancelled, let self else { return }
            await MainActor.run {
                if self.cameraErrorMessage == message {
                    self.cameraErrorMessage = nil
                }
            }
        }
    }

    func addImageFromLibrary(_ image: UIImage) {
        capturedImages.append(image)
        showSuccessMessage = true
        
        Task {
            try? await Task.sleep(nanoseconds: feedbackDuration)
            await MainActor.run {
                showSuccessMessage = false
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard index < capturedImages.count else { return }
        capturedImages.remove(at: index)
    }
}
