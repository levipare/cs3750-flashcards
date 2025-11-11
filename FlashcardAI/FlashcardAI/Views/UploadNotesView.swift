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
    @State private var isGeneratingQuestions = false
    @State private var showQuestionTypePicker = false
    @State private var showGenerationResult = false
    @State private var generationResult = ""
    @State private var generationError: String?

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
            
            if isGeneratingQuestions {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Generating questions…")
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
                    showQuestionTypePicker = true
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
        .confirmationDialog(
            "Select question type",
            isPresented: $showQuestionTypePicker,
            titleVisibility: .visible
        ) {
            ForEach(QuestionType.allCases) { type in
                Button(type.displayName) {
                    Task {
                        await generateQuestions(for: type)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showGenerationResult) {
            NavigationView {
                ScrollView {
                    Text(generationResult)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle("Generated Questions")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showGenerationResult = false
                        }
                    }
                }
            }
        }
        .alert(
            "Generation failed",
            isPresented: Binding(
                get: { generationError != nil },
                set: { if !$0 { generationError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(generationError ?? "")
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
            return try await promptText(for: "cleanOCR")
        } catch {
            print("Failed to fetch prompts: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func generateQuestions(for type: QuestionType) async {
        guard !inputText.isEmpty else { return }
        
        await MainActor.run {
            isGeneratingQuestions = true
            generationError = nil
        }
        
        do {
            let systemPrompt = try await promptText(for: "system")
            let questionPrompt = try await promptText(for: type.promptID)
            let combinedPrompt = """
            \(systemPrompt)
            
            \(questionPrompt)
            
            SOURCE_TEXT:
            
            \(inputText)
            """
            let response = try await llmService.sendMessage(prompt: combinedPrompt)
            await MainActor.run {
                generationResult = response
                showGenerationResult = true
            }
        } catch {
            await MainActor.run {
                generationError = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isGeneratingQuestions = false
        }
    }
    
    private func promptText(for id: String) async throws -> String {
        if let prompt = try await firestoreManager.fetchPrompt(withID: id) {
            return prompt.text
        }
        throw PromptFetchError.missingPrompt(id)
    }
}

enum PromptFetchError: Error {
    case missingPrompt(String)
}

enum QuestionType: String, CaseIterable, Identifiable {
    case cloze = "user_flashcard_cloze"
    case definition = "user_flashcard_definition"
    case multipleChoice = "user_flashcard_mcq"
    case trueFalse = "user_flashcard_true_false"
    case shortAnswer = "user_flashcard_short_answer"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cloze: return "Cloze"
        case .definition: return "Definition"
        case .multipleChoice: return "Multiple Choice"
        case .trueFalse: return "True/False"
        case .shortAnswer: return "Short Answer"
        }
    }
    
    var promptID: String { rawValue }
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
