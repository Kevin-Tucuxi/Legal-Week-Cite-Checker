import Foundation
import SwiftData

@Model
final class Citation {
    var id: UUID
    var originalText: String
    var normalizedCitation: String?
    var caseName: String?
    var citationStatus: CitationStatus
    var caseNameStatus: CaseNameStatus
    var clusterId: String?
    var courtListenerUrl: String?
    var timestamp: Date
    var opinionText: String?
    
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
        opinionText: String? = nil
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
    }
}

enum CitationStatus: String, Codable {
    case pending
    case valid
    case invalid
}

enum CaseNameStatus: String, Codable {
    case pending
    case valid
    case invalid
} 