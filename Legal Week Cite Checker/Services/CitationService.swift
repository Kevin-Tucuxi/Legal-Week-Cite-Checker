import Foundation
import SwiftData

@MainActor
class CitationService: ObservableObject {
    private let api = CourtListenerAPI.shared
    @Published var citations: [Citation] = []
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func validateText(_ text: String) async throws {
        print("\n=== Starting Citation Validation ===")
        print("Input text: \(text)")
        
        // Extract potential citations using regex
        let citations = extractCitations(from: text)
        print("Extracted citations: \(citations)")
        
        for citationText in citations {
            print("\nProcessing citation: \(citationText)")
            let citation = Citation(originalText: citationText)
            modelContext.insert(citation)
            
            do {
                // First try to validate the citation
                print("Attempting citation validation...")
                let responses: [CitationResponse] = try await api.validateCitation(citationText)
                
                if let response = responses.first {
                    print("Citation validation response: \(response)")
                    
                    if response.status == 200 && !response.clusters.isEmpty {
                        print("Citation validation successful")
                        // Citation is valid
                        citation.citationStatus = .valid
                        citation.normalizedCitation = response.normalizedCitations.first
                        citation.clusterId = response.clusters.first?.stringId
                        citation.courtListenerUrl = "https://www.courtlistener.com\(response.clusters.first?.absoluteUrl ?? "")"
                        citation.caseName = response.clusters.first?.caseName
                        citation.caseNameStatus = .valid
                    } else {
                        print("Citation validation failed, attempting case name search...")
                        // Citation is invalid, try to find by case name
                        citation.citationStatus = .invalid
                        
                        if let caseName = extractCaseName(from: citationText) {
                            print("Extracted case name: \(caseName)")
                            let searchResponse = try await api.searchCaseName(caseName)
                            
                            if searchResponse.count == 1 {
                                print("Found unique case match")
                                let result = searchResponse.results[0]
                                citation.caseNameStatus = .valid
                                citation.caseName = result.caseName
                                citation.clusterId = result.clusterId
                                citation.courtListenerUrl = "https://www.courtlistener.com\(result.absoluteUrl)"
                                
                                // Get the opinion text
                                print("Fetching opinion text...")
                                let opinionResponse = try await api.getOpinionText(clusterId: result.clusterId)
                                citation.opinionText = opinionResponse.plainText
                            } else {
                                print("No unique case match found")
                                citation.caseNameStatus = .invalid
                            }
                        } else {
                            print("No case name found in citation")
                            citation.caseNameStatus = .invalid
                        }
                    }
                } else {
                    print("No citation validation response received")
                    citation.citationStatus = .invalid
                    citation.caseNameStatus = .invalid
                }
            } catch {
                print("Error processing citation: \(error)")
                citation.citationStatus = .invalid
                citation.caseNameStatus = .invalid
            }
        }
        
        try modelContext.save()
        print("\n=== Citation Validation Complete ===")
    }
    
    private func extractCitations(from text: String) -> [String] {
        // Basic citation pattern matching
        // This can be enhanced with more sophisticated patterns
        let pattern = #"(?:\d+)\s+(?:[A-Za-z\.]+)\s+(?:\d+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, range: range) ?? []
        
        let citations = matches.compactMap { (match: NSTextCheckingResult) -> String? in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
        
        print("Found \(citations.count) potential citations")
        return citations
    }
    
    private func extractCaseName(from text: String) -> String? {
        // Basic case name pattern matching
        // This can be enhanced with more sophisticated patterns
        let pattern = #"([A-Za-z\s]+)\s+v\.\s+([A-Za-z\s]+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex?.firstMatch(in: text, range: range) {
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
        
        return nil
    }
    
    func deleteCitation(_ citation: Citation) {
        modelContext.delete(citation)
        try? modelContext.save()
    }
} 