//
//  UploadImagesView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//

import SwiftUI
import UIKit
import PhotosUI
import VisionKit

struct UploadImagesView: View {

    @State private var viewModel = ViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isExtracting = false
    @State private var progressCompleted = 0
    @State private var progressTotal = 0
    @State private var combinedText: String = ""
    @State private var showTextPreview = false
    @State private var showScanner = false

    private let ocrManager = OCRManager()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black.opacity(0.55), Color.clear],
                           startPoint: .bottom,
                           endPoint: .top)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.showSuccessMessage {
                    successBanner()
                }
                
                Spacer(minLength: 0)
                
                bottomControlsSection()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(), value: viewModel.showSuccessMessage)

            if isExtracting {
                extractionProgressOverlay()
            }
        }
        .foregroundColor(.white)
        .alert("Camera unavailable", isPresented: Binding(
            get: { viewModel.cameraErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.cameraErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                viewModel.cameraErrorMessage = nil
            }
        } message: {
            Text(viewModel.cameraErrorMessage ?? "Please try again.")
        }
        .sheet(isPresented: $showTextPreview) {
            textPreviewSheet()
        }
        .sheet(isPresented: $showScanner) {
            documentScannerSheet()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
    }
}

// MARK: - View Components
private extension UploadImagesView {
    
    @ViewBuilder
    func successBanner() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            Text("Image(s) added!")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.75))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    func bottomControlsSection() -> some View {
        VStack(spacing: 16) {
            actionButtonsRow()
            extractTextButton()
            
            if !viewModel.capturedImages.isEmpty {
                imageScrollView()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    func actionButtonsRow() -> some View {
        HStack(spacing: 40) {
            photoLibraryButton()
            scanButton()
            imageCountBadge()
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    func photoLibraryButton() -> some View {
        PhotosPicker(selection: $selectedPhotoItem,
                     matching: .images,
                     photoLibrary: .shared()) {
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 30))
                Text("Library")
                    .font(.caption)
            }
            .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    func scanButton() -> some View {
        Button(action: { showScanner = true }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 70, height: 70)
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 28, weight: .semibold))
                }
                Text("Scan")
                    .font(.caption)
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    func imageCountBadge() -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                Text("\(viewModel.capturedImages.count)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text("Images")
                .font(.caption)
        }
        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
    }
    
    @ViewBuilder
    func extractTextButton() -> some View {
        let isEmpty = viewModel.capturedImages.isEmpty
        
        Button(action: startOCR) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                Text(isExtracting ? "Extracting..." : "Extract Text")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(isEmpty ? 0.4 : 0.9))
            .clipShape(Capsule())
        }
        .disabled(isEmpty || isExtracting)
        .opacity((isEmpty || isExtracting) ? 0.6 : 1)
    }
    
    @ViewBuilder
    func imageScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) { index, image in
                    imageThumbnail(image: image, index: index)
                }
            }
        }
        .frame(height: 100)
    }
    
    @ViewBuilder
    func imageThumbnail(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: {
                viewModel.removeImage(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(4)
        }
    }
    
    @ViewBuilder
    func extractionProgressOverlay() -> some View {
        VStack(spacing: 12) {
            ProgressView(value: progressTotal == 0 ? 0 : Double(progressCompleted) / Double(progressTotal))
                .progressViewStyle(.linear)
                .frame(width: 220)
            Text("Processing \(progressCompleted)/\(progressTotal) images…")
                .font(.footnote)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func textPreviewSheet() -> some View {
        NavigationStack {
            ScrollView {
                Text(combinedText.isEmpty ? "No text recognized." : combinedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Extracted Text (TESTING)")
        }
    }
    
    @ViewBuilder
    func documentScannerSheet() -> some View {
        DocumentScannerView(
            onCancel: {
                showScanner = false
            },
            onImages: { images in
                for img in images {
                    viewModel.addImageFromLibrary(img)
                }
                showScanner = false
            },
            onFailure: { error in
                viewModel.cameraErrorMessage = error.localizedDescription
                showScanner = false
            }
        )
    }
}

// MARK: - Helper Methods
private extension UploadImagesView {
    
    func startOCR() {
        let images = viewModel.capturedImages
        guard !images.isEmpty else { return }
        isExtracting = true
        progressCompleted = 0
        progressTotal = images.count

        let pairs: [(UUID, UIImage)] = images.map { (UUID(), $0) }
        Task {
            let dict = await ocrManager.recognize(images: pairs) { prog in
                DispatchQueue.main.async {
                    self.progressCompleted = prog.completed
                    self.progressTotal = prog.total
                }
            }
            let ordered = pairs.compactMap { pair in dict[pair.0]?.text }
            await MainActor.run {
                self.combinedText = ordered.joined(separator: "\n\n")
                self.isExtracting = false
                self.showTextPreview = true
            }
        }
    }
    
    func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else { return }
        Task {
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.addImageFromLibrary(uiImage)
                    }
                }
            } catch {
                print("Failed to load photo from picker:", error)
            }
            await MainActor.run {
                selectedPhotoItem = nil
            }
        }
    }
}

// MARK: - Document Scanner
fileprivate struct DocumentScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = VNDocumentCameraViewController

    let onCancel: () -> Void
    let onImages: (_ images: [UIImage]) -> Void
    let onFailure: (_ error: Error) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            parent.onFailure(error)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                let img = scan.imageOfPage(at: i)
                images.append(img)
            }
            parent.onImages(images)
        }
    }
}
