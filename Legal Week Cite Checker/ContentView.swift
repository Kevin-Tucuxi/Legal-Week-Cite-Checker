//
//  ContentView.swift
//  Legal Week Cite Checker
//
//  Created by Kevin Keller on 3/26/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var citationService: CitationService
    @Query private var citations: [Citation]
    @State private var inputText: String = ""
    @State private var showingDocumentPicker = false
    @State private var showingAPITokenView = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationSplitView {
            List {
                Section {
                    TextEditor(text: $inputText)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAPITokenView = true }) {
                        Label("API Token", systemImage: "key")
                    }
                }
            }
        } detail: {
            Text("Select a citation to view details")
        }
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
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
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
    
    private func deleteCitations(offsets: IndexSet) {
        for index in offsets {
            citationService.deleteCitation(citations[index])
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Citation.self, inMemory: true)
        .environmentObject(CitationService(modelContext: try! ModelContainer(for: Citation.self).mainContext))
}
