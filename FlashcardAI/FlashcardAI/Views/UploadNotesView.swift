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

    private let ocrManager = OCRManager()
    
    var body: some View {
        TextEditor(text: $inputText)
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
                        for item in selectedPhotoItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) {
                               images.append(image)
                           }
                        }
                        selectedPhotoItems = []
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
                    for img in imgs {
                        images.append(img)
                    }
                    showScanner = false
                },
                onFailure: { error in
                    // TODO show error message
                    showScanner = false
                }
            )
        }
    }
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
