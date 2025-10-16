//
//  UploadImagesView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import SwiftUI
import PhotosUI

struct UploadImagesView: View {
    
    @State private var viewModel = ViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Camera preview
                CameraView(image: $viewModel.currentFrame)
                    .frame(maxHeight: .infinity)
                
                // Bottom controls and image gallery
                VStack(spacing: 16) {
                    // Control buttons
                    HStack(spacing: 40) {
                        // Upload from library button
                        PhotosPicker(selection: $selectedPhotoItem,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 30))
                                Text("Library")
                                    .font(.caption)
                            }
                        }
                        
                        // Capture photo button
                        Button(action: {
                            viewModel.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        // Image count indicator
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
                    }
                    .padding(.vertical)
                    
                    // Thumbnail gallery
                    if !viewModel.capturedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        // Delete button
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
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 100)
                    }
                }
                .background(.ultraThinMaterial)
            }
            
            // Success message overlay
            if viewModel.showSuccessMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Image uploaded successfully!")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: viewModel.showSuccessMessage)
            }
        }
        .foregroundColor(.white)
        .onChange(of: selectedPhotoItem) { _, newItem in
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
}

//#Preview {
//    UploadImagesView()
//}
