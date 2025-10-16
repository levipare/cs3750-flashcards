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
    var showImagePicker = false
    
    private let cameraManager = CameraManager()
    
    init() {
        cameraManager.start()
        Task {
            await loadFrames()
        }
    }
    
    private func loadFrames() async {
        for await frame in cameraManager.previewStream {
            await MainActor.run {
                currentFrame = frame
            }
        }
    }

    func capturePhoto() {
        Task {
            do {
                let img = try await cameraManager.capturePhoto()
                await MainActor.run {
                    capturedImages.append(img)
                    showSuccessMessage = true
                }
                
                // Hide success message after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    showSuccessMessage = false
                }
            } catch {
                print("Photo capture failed:", error)
            }
        }
    }
    
    func addImageFromLibrary(_ image: UIImage) {
        capturedImages.append(image)
        showSuccessMessage = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
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
