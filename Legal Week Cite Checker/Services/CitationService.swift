import Foundation
import SwiftData

// A service that handles the validation of legal citations
// This service coordinates between the UI and the CourtListener API,
// managing the validation process and storing results in SwiftData
@MainActor
class CitationService: ObservableObject {
    // The API client used to communicate with CourtListener
    private let api = CourtListenerAPI.shared
    // The list of citations that have been validated
    @Published var citations: [Citation] = []
    // The SwiftData model context used to save citations
    private let modelContext: ModelContext
    
    // Creates a new CitationService with the given model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Validates a piece of text containing legal citations
    // This method:
    // 1. Extracts potential citations and case names from the text
    // 2. Validates each citation against CourtListener
    // 3. If a citation is invalid, tries to find the case by name
    // 4. Stores all results in SwiftData
    func validateText(_ text: String) async throws {
        print("\n=== Starting Citation Validation ===")
        print("Input text: \(text)")
        
        // Split the text into lines and process each line
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            print("\nProcessing line: \(line)")
            
            let citationObj = Citation(originalText: line)
            modelContext.insert(citationObj)
            
            // First try our local parsing
            if let (caseName, citation) = extractCaseNameAndCitation(from: line) {
                print("Extracted case name: \(caseName)")
                print("Extracted citation: \(citation)")
                
                citationObj.caseName = caseName
                
                do {
                    // Try to validate the citation
                    print("Attempting citation validation...")
                    let responses: [CitationResponse] = try await api.validateCitation(citation)
                    
                    if let response = responses.first {
                        print("Citation validation response: \(response)")
                        
                        if response.status == 200 && !response.clusters.isEmpty {
                            print("Citation validation successful")
                            // Citation is valid
                            citationObj.citationStatus = .valid
                            citationObj.normalizedCitation = response.normalizedCitations.first
                            citationObj.clusterId = response.clusters.first?.stringId
                            citationObj.courtListenerUrl = "https://www.courtlistener.com\(response.clusters.first?.absoluteUrl ?? "")"
                            citationObj.caseName = response.clusters.first?.caseName
                            citationObj.caseNameStatus = .valid
                        } else {
                            print("Citation validation failed, attempting case name search...")
                            // Citation is invalid, try to find by case name
                            citationObj.citationStatus = .invalid
                            await searchAndUpdateCaseName(citationObj, caseName: caseName)
                        }
                    } else {
                        print("No citation validation response received")
                        citationObj.citationStatus = .invalid
                        await searchAndUpdateCaseName(citationObj, caseName: caseName)
                    }
                } catch {
                    print("Error processing citation: \(error)")
                    citationObj.citationStatus = .invalid
                    await searchAndUpdateCaseName(citationObj, caseName: caseName)
                }
            } else {
                print("Local parsing failed, attempting API citation lookup...")
                // Try the citation-lookup API
                do {
                    let responses = try await api.lookupCitationsInText(line)
                    
                    if let response = responses.first {
                        print("API citation lookup response: \(response)")
                        
                        if response.status == 200 && !response.clusters.isEmpty {
                            print("API citation lookup successful")
                            // Citation is valid
                            citationObj.citationStatus = .valid
                            citationObj.normalizedCitation = response.normalizedCitations.first
                            citationObj.clusterId = response.clusters.first?.stringId
                            citationObj.courtListenerUrl = "https://www.courtlistener.com\(response.clusters.first?.absoluteUrl ?? "")"
                            citationObj.caseName = response.clusters.first?.caseName
                            citationObj.caseNameStatus = .valid
                        } else {
                            print("API citation lookup failed, attempting case name search...")
                            // Try to extract case name and search
                            if let caseName = extractCaseName(from: line) {
                                print("Extracted case name only: \(caseName)")
                                citationObj.caseName = caseName
                                citationObj.citationStatus = .invalid
                                await searchAndUpdateCaseName(citationObj, caseName: caseName)
                            } else {
                                print("Could not extract case name from line")
                                citationObj.citationStatus = .invalid
                                citationObj.caseNameStatus = .invalid
                            }
                        }
                    } else {
                        print("No API citation lookup response received")
                        // Try case name search as last resort
                        if let caseName = extractCaseName(from: line) {
                            print("Extracted case name only: \(caseName)")
                            citationObj.caseName = caseName
                            citationObj.citationStatus = .invalid
                            await searchAndUpdateCaseName(citationObj, caseName: caseName)
                        } else {
                            print("Could not extract case name from line")
                            citationObj.citationStatus = .invalid
                            citationObj.caseNameStatus = .invalid
                        }
                    }
                } catch {
                    print("Error in API citation lookup: \(error)")
                    // Try case name search as last resort
                    if let caseName = extractCaseName(from: line) {
                        print("Extracted case name only: \(caseName)")
                        citationObj.caseName = caseName
                        citationObj.citationStatus = .invalid
                        await searchAndUpdateCaseName(citationObj, caseName: caseName)
                    } else {
                        print("Could not extract case name from line")
                        citationObj.citationStatus = .invalid
                        citationObj.caseNameStatus = .invalid
                    }
                }
            }
        }
        
        try modelContext.save()
        print("\n=== Citation Validation Complete ===")
    }
    
    // Extracts both the case name and citation from a line of text
    // Returns a tuple of (caseName, citation) if successful, nil otherwise
    private func extractCaseNameAndCitation(from line: String) -> (caseName: String, citation: String)? {
        // First try to extract just the citation part
        // This pattern looks for common citation formats:
        // - 534 F.3d 1290
        // - 123 F. Supp. 2d 456
        // - 789 F.2d 123
        let citationPattern = #"(\d+\s+[A-Z\.]+\s+\d+)"#
        
        if let regex = try? NSRegularExpression(pattern: citationPattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            
            let citationRange = Range(match.range(at: 1), in: line)!
            let citation = String(line[citationRange]).trimmingCharacters(in: .whitespaces)
            
            // Now try to extract the case name from before the citation
            if let commaIndex = line.firstIndex(of: ",") {
                let caseName = String(line[..<commaIndex]).trimmingCharacters(in: .whitespaces)
                print("Extracted case name: \(caseName)")
                print("Extracted citation: \(citation)")
                return (caseName, citation)
            }
        }
        
        // If we couldn't find a citation, try to extract just the case name
        let caseNamePattern = #"([A-Za-z\.\s]+(?:\s+(?:v\.|vs\.|versus)\s+[A-Za-z\.\s]+))"#
        if let regex = try? NSRegularExpression(pattern: caseNamePattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            
            let caseNameRange = Range(match.range(at: 1), in: line)!
            let caseName = String(line[caseNameRange]).trimmingCharacters(in: .whitespaces)
            
            // Try to find any citation-like text after the case name
            let remainingText = String(line[line.index(after: caseNameRange.upperBound)...]).trimmingCharacters(in: .whitespaces)
            if let citationMatch = try? NSRegularExpression(pattern: citationPattern).firstMatch(in: remainingText, range: NSRange(remainingText.startIndex..., in: remainingText)),
               let citationRange = Range(citationMatch.range(at: 1), in: remainingText) {
                
                let citation = String(remainingText[citationRange]).trimmingCharacters(in: .whitespaces)
                print("Extracted case name: \(caseName)")
                print("Extracted citation: \(citation)")
                return (caseName, citation)
            }
        }
        
        print("Could not extract case name and citation from line: \(line)")
        return nil
    }
    
    // Extracts just the case name from a line of text
    private func extractCaseName(from line: String) -> String? {
        // Pattern for case names with "v." or "vs." or "versus"
        // Updated to handle abbreviations like "U.S."
        let pattern = #"([A-Za-z\.\s]+(?:\s+(?:v\.|vs\.|versus)\s+[A-Za-z\.\s]+))"#
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            let caseNameRange = Range(match.range(at: 1), in: line)!
            return String(line[caseNameRange]).trimmingCharacters(in: .whitespaces)
        }
        
        return nil
    }
    
    // Helper function to search for a case by name and update the citation object
    private func searchAndUpdateCaseName(_ citationObj: Citation, caseName: String) async {
        do {
            print("Searching for case name: \(caseName)")
            let searchResponse = try await api.searchCaseName(caseName)
            
            // Look for an exact match of the case name
            if let exactMatch = searchResponse.first(where: { $0.caseName == caseName }) {
                print("Found exact case name match: \(exactMatch.caseName)")
                
                // Update the citation with the exact match
                citationObj.caseNameStatus = .valid
                citationObj.clusterId = String(exactMatch.clusterId)
                citationObj.courtListenerUrl = "https://www.courtlistener.com\(exactMatch.absoluteUrl)"
                
                // If there are additional matches, add them to the notes
                let otherMatches = searchResponse.filter { $0.caseName != caseName }
                if !otherMatches.isEmpty {
                    var additionalMatches = "Additional similar cases found:\n"
                    for result in otherMatches {
                        additionalMatches += "- \(result.caseName) (\(result.court), \(result.dateFiled))\n"
                    }
                    citationObj.notes = additionalMatches
                }
                
                print("Updated citation with exact case name match")
            } else {
                print("No exact case name match found")
                citationObj.caseNameStatus = .invalid
                citationObj.clusterId = nil
                citationObj.courtListenerUrl = nil
                
                // Add similar cases to notes for reference
                if !searchResponse.isEmpty {
                    var similarCases = "Similar cases found (but not exact matches):\n"
                    for result in searchResponse {
                        similarCases += "- \(result.caseName) (\(result.court), \(result.dateFiled))\n"
                    }
                    citationObj.notes = similarCases
                }
            }
        } catch {
            print("Error searching case name: \(error)")
            citationObj.caseNameStatus = .invalid
        }
    }
    
    // Deletes a citation from the database
    func deleteCitation(_ citation: Citation) {
        modelContext.delete(citation)
        try? modelContext.save()
    }
} 