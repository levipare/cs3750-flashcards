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
            CameraView(image: $viewModel.currentFrame)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.black.opacity(0.55), Color.clear],
                           startPoint: .bottom,
                           endPoint: .top)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.showSuccessMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Image uploaded successfully!")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer(minLength: 0)

                VStack(spacing: 16) {
                    let isCameraUnavailable = viewModel.currentFrame == nil
                    HStack(spacing: 40) {
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
                        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                        .disabled(isCameraUnavailable)
                        .opacity(isCameraUnavailable ? 0.5 : 1)

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
                    .padding(.vertical)

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
                        }
                        .frame(height: 100)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(), value: viewModel.showSuccessMessage)
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
