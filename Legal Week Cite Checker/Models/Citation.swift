import Foundation
import SwiftData

// The main data model for storing citation information
// This class represents a legal citation and its validation status
@Model
final class Citation {
    // Unique identifier for the citation
    var id: UUID
    // The original citation text as entered by the user
    var originalText: String
    // The standardized version of the citation (e.g., "347 U.S. 483")
    var normalizedCitation: String?
    // The name of the case (e.g., "Brown v. Board of Education")
    var caseName: String?
    // Whether the citation was found to be valid in CourtListener
    var citationStatus: CitationStatus
    // Whether the case name was found to be valid in CourtListener
    var caseNameStatus: CaseNameStatus
    // The unique identifier for the case in CourtListener's database
    var clusterId: String?
    // The full URL to view the case on CourtListener's website
    var courtListenerUrl: String?
    // When the citation was added to the app
    var timestamp: Date
    // The full text of the court's opinion
    var opinionText: String?
    // Additional notes about the citation (e.g., multiple matches found)
    var notes: String?
    
    // Creates a new Citation with the given text
    // The status fields start as .pending and are updated as validation occurs
    init(
        id: UUID = UUID(),
        originalText: String,
        normalizedCitation: String? = nil,
        caseName: String? = nil,
        citationStatus: CitationStatus = .pending,
        caseNameStatus: CaseNameStatus = .pending,
        clusterId: String? = nil,
        courtListenerUrl: String? = nil,
        timestamp: Date = Date(),
        opinionText: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.originalText = originalText
        self.normalizedCitation = normalizedCitation
        self.caseName = caseName
        self.citationStatus = citationStatus
        self.caseNameStatus = caseNameStatus
        self.clusterId = clusterId
        self.courtListenerUrl = courtListenerUrl
        self.timestamp = timestamp
        self.opinionText = opinionText
        self.notes = notes
    }
}

// Represents whether a citation was found to be valid in CourtListener
enum CitationStatus: String, Codable {
    case pending   // Citation hasn't been checked yet
    case valid     // Citation was found in CourtListener
    case invalid   // Citation wasn't found in CourtListener
}

// Represents whether a case name was found to be valid in CourtListener
enum CaseNameStatus: String, Codable {
    case pending   // Case name hasn't been checked yet
    case valid     // Case name was found in CourtListener
    case invalid   // Case name wasn't found in CourtListener
} 