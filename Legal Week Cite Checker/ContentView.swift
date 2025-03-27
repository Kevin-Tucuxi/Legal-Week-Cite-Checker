//
//  ContentView.swift
//  Legal Week Cite Checker
//
//  Created by Kevin Keller on 3/26/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// The main view of the app that provides the user interface for:
// 1. Entering or uploading text containing citations
// 2. Validating the citations
// 3. Viewing the results of the validation
struct ContentView: View {
    // The SwiftData model context for saving citations
    @Environment(\.modelContext) private var modelContext
    // The citation service that handles validation
    @EnvironmentObject private var citationService: CitationService
    // The list of citations that have been validated
    @Query private var citations: [Citation]
    // The text input field for entering citations
    @State private var inputText: String = ""
    // Whether to show the document picker for file uploads
    @State private var showingDocumentPicker = false
    // Whether to show the API token management view
    @State private var showingAPITokenView = false
    // Whether to show an error alert
    @State private var showingError = false
    // The message to display in the error alert
    @State private var errorMessage = ""
    // Whether a validation operation is in progress
    @State private var isProcessing = false
    
    // The main view body
    var body: some View {
        NavigationSplitView {
            List {
                // Section for text input and validation controls
                Section {
                    // Text editor for entering citations
                    TextEditor(text: $inputText)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    // Buttons for validating citations and uploading documents
                    HStack {
                        Button(action: validateText) {
                            Label("Validate Citations", systemImage: "checkmark.circle")
                        }
                        .disabled(inputText.isEmpty || isProcessing)
                        
                        Button(action: { showingDocumentPicker = true }) {
                            Label("Upload Document", systemImage: "doc.badge.plus")
                        }
                        .disabled(isProcessing)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Section for displaying validation results
                if !citations.isEmpty {
                    Section("Results") {
                        ForEach(citations) { citation in
                            CitationResultView(citation: citation)
                        }
                        .onDelete(perform: deleteCitations)
                    }
                }
            }
            .navigationTitle("Citation Checker")
            .toolbar {
                // Button to manage the API token
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAPITokenView = true }) {
                        Label("API Token", systemImage: "key")
                    }
                }
            }
        } detail: {
            Text("Select a citation to view details")
        }
        // File picker for uploading documents
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                guard let file = files.first else { return }
                handleImportedFile(file)
            case .failure(let error):
                showError(error.localizedDescription)
            }
        }
        // Sheet for managing the API token
        .sheet(isPresented: $showingAPITokenView) {
            NavigationView {
                APITokenView()
                    .navigationTitle("API Token")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingAPITokenView = false
                            }
                        }
                    }
            }
        }
        // Alert for displaying errors
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // Validates the text input using the citation service
    private func validateText() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        Task {
            do {
                try await citationService.validateText(inputText)
            } catch {
                showError(error.localizedDescription)
            }
            isProcessing = false
        }
    }
    
    // Handles an imported file by reading its contents
    private func handleImportedFile(_ file: URL) {
        guard file.startAccessingSecurityScopedResource() else {
            showError("Failed to access the selected file")
            return
        }
        
        defer { file.stopAccessingSecurityScopedResource() }
        
        do {
            let text: String
            if file.pathExtension.lowercased() == "pdf" {
                // TODO: Implement PDF text extraction
                showError("PDF support coming soon")
                return
            } else {
                text = try String(contentsOf: file, encoding: .utf8)
            }
            
            inputText = text
            validateText()
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    // Deletes citations from the list
    private func deleteCitations(offsets: IndexSet) {
        for index in offsets {
            citationService.deleteCitation(citations[index])
        }
    }
    
    // Shows an error alert with the given message
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// Preview provider for SwiftUI previews
#Preview {
    ContentView()
        .modelContainer(for: Citation.self, inMemory: true)
        .environmentObject(CitationService(modelContext: try! ModelContainer(for: Citation.self).mainContext))
}
