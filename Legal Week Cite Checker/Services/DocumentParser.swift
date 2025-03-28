import Foundation
import PDFKit
import UniformTypeIdentifiers

/// Represents possible errors that can occur during document parsing
enum DocumentParserError: Error {
    /// The file type is not supported by the parser
    case unsupportedFileType
    /// An error occurred while parsing the document
    case parsingError(String)
}

/// A service class responsible for parsing different types of documents and extracting legal citations
/// This class handles PDF, Word, and plain text files, cleaning the extracted text and identifying
/// legal citations in various formats.
class DocumentParser {
    /// Shared instance of the DocumentParser for use throughout the application
    static let shared = DocumentParser()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Parses a document at the given URL and extracts legal citations
    /// - Parameter url: The URL of the document to parse
    /// - Returns: A string containing extracted and cleaned citations
    /// - Throws: DocumentParserError if the file type is unsupported or parsing fails
    func parseDocument(at url: URL) async throws -> String {
        let fileType = try getFileType(from: url)
        
        switch fileType {
        case .pdf:
            return try await parsePDF(at: url)
        case .word, .docx:
            return try await parseWord(at: url)
        case .plainText:
            return try await parseText(at: url)
        default:
            throw DocumentParserError.unsupportedFileType
        }
    }
    
    /// Determines the file type of a document at the given URL
    /// - Parameter url: The URL of the document to check
    /// - Returns: The UTType of the document
    /// - Throws: DocumentParserError if the file type cannot be determined or is unsupported
    private func getFileType(from url: URL) throws -> UTType {
        guard let fileType = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
              let utType = UTType(fileType) else {
            throw DocumentParserError.unsupportedFileType
        }
        
        if utType.conforms(to: .pdf) {
            return .pdf
        } else if utType.conforms(to: .word) || utType.conforms(to: .docx) {
            return .word
        } else if utType.conforms(to: .plainText) {
            return .plainText
        } else {
            throw DocumentParserError.unsupportedFileType
        }
    }
    
    /// Parses a PDF document and extracts its text content
    /// - Parameter url: The URL of the PDF file
    /// - Returns: A string containing extracted and cleaned citations
    /// - Throws: DocumentParserError if the PDF cannot be opened or parsed
    private func parsePDF(at url: URL) async throws -> String {
        guard let pdf = PDFDocument(url: url) else {
            throw DocumentParserError.parsingError("Could not open PDF file")
        }
        
        var text = ""
        for i in 0..<pdf.pageCount {
            if let page = pdf.page(at: i) {
                text += page.string ?? ""
            }
        }
        return cleanAndExtractCitations(from: text)
    }
    
    /// Parses a Word document and extracts its text content
    /// - Parameter url: The URL of the Word file
    /// - Returns: A string containing extracted and cleaned citations
    /// - Throws: DocumentParserError if the text cannot be extracted from the Word document
    private func parseWord(at url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        if let text = String(data: data, encoding: .utf8) {
            return cleanAndExtractCitations(from: text)
        } else if let text = String(data: data, encoding: .ascii) {
            return cleanAndExtractCitations(from: text)
        } else {
            throw DocumentParserError.parsingError("Could not extract text from Word document")
        }
    }
    
    /// Parses a plain text document
    /// - Parameter url: The URL of the text file
    /// - Returns: A string containing extracted and cleaned citations
    /// - Throws: DocumentParserError if the text file cannot be read
    private func parseText(at url: URL) async throws -> String {
        let text = try String(contentsOf: url, encoding: .utf8)
        return cleanAndExtractCitations(from: text)
    }
    
    /// Cleans and extracts legal citations from text content
    /// This method processes the text line by line, identifying and extracting:
    /// 1. Full Bluebook-style citations (e.g., "Case Name, Volume Reporter Page (Court Year)")
    /// 2. Case names with various formats (e.g., "Plaintiff v. Defendant")
    /// 3. Westlaw citations (e.g., "2024 WL 123456")
    /// - Parameter text: The raw text to process
    /// - Returns: A string containing cleaned and extracted citations, one per line
    private func cleanAndExtractCitations(from text: String) -> String {
        // Split text into lines and process each line
        let lines = text.components(separatedBy: .newlines)
        var cleanedLines: [String] = []
        
        // Regular expressions for finding citations
        // Pattern for standard Bluebook case citations: Case Name, Volume Reporter Page (Court Year)
        let citationPattern = #"([A-Za-z\s]+(?:\s+v\.\s+[A-Za-z\s]+)?),\s*(\d+\s+[A-Z\.]+\s+\d+)\s*\(([^)]+)\)"#
        
        // Pattern for case names with "v." or "vs." or "versus"
        let caseNamePattern = #"([A-Za-z\s]+(?:\s+(?:v\.|vs\.|versus)\s+[A-Za-z\s]+))"#
        
        // Pattern for WL citations (Westlaw)
        let westlawPattern = #"(\d{4}\s+WL\s+\d+)"#
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and common header/footer content
            if trimmedLine.isEmpty ||
               trimmedLine.contains("FILED") ||
               trimmedLine.contains("Page") ||
               trimmedLine.contains("Case No.") ||
               trimmedLine.contains("ORDER") ||
               trimmedLine.contains("IT IS ORDERED") ||
               trimmedLine.contains("UNITED STATES DISTRICT COURT") {
                continue
            }
            
            // Look for full citations first
            if let range = trimmedLine.range(of: citationPattern, options: .regularExpression) {
                let citation = String(trimmedLine[range])
                cleanedLines.append(citation)
            }
            // Look for case names that might not have citations
            else if let range = trimmedLine.range(of: caseNamePattern, options: .regularExpression) {
                let caseName = String(trimmedLine[range])
                // Only add if it's not already in the list
                if !cleanedLines.contains(caseName) {
                    cleanedLines.append(caseName)
                }
            }
            // Look for standalone WL citations
            else if let range = trimmedLine.range(of: westlawPattern, options: .regularExpression) {
                let citation = String(trimmedLine[range])
                cleanedLines.append(citation)
            }
        }
        
        // Remove duplicates while preserving order
        let uniqueLines = Array(NSOrderedSet(array: cleanedLines)) as? [String] ?? cleanedLines
        
        // Join the cleaned lines with newlines
        return uniqueLines.joined(separator: "\n")
    }
}

/// Extension to define custom UTType for Word documents
/// This allows the parser to recognize both .doc and .docx file formats
extension UTType {
    /// Represents Microsoft Word .doc files
    static let word = UTType("com.microsoft.word.doc")!
    /// Represents Microsoft Word .docx files
    static let docx = UTType("org.openxmlformats.wordprocessingml.document")!
} 