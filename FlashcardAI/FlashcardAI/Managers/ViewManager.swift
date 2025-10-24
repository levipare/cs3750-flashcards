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
    var capturedImages: [UIImage] = []
    var showSuccessMessage = false
    var cameraErrorMessage: String?
	var feedbackDuration: UInt64 = 2_000_000_000  // 2 seconds


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
