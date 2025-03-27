import Foundation

// Errors that can occur when interacting with the CourtListener API
enum CourtListenerAPIError: Error {
    case invalidURL           // The API URL is not valid
    case invalidResponse      // The API returned an unexpected response
    case invalidData         // The API returned data that couldn't be processed
    case unauthorized        // The API token is invalid or missing
    case rateLimitExceeded   // Too many requests to the API
    case unknown(Error)      // Any other error that might occur
}

// A service that handles all communication with the CourtListener API
// This is implemented as an actor to ensure thread-safe access to the API token
// and to prevent multiple simultaneous API calls from interfering with each other
actor CourtListenerAPI {
    // The base URL for all CourtListener API requests
    private let baseURL = "https://www.courtlistener.com/api/rest/v4"
    // The API token used to authenticate requests
    private var apiToken: String?
    
    // A shared instance of the API client that can be used throughout the app
    static let shared = CourtListenerAPI()
    
    // Private initializer to ensure we only use the shared instance
    private init() {}
    
    // Sets the API token that will be used for all future requests
    func setAPIToken(_ token: String) {
        self.apiToken = token
        print("API Token set: \(token.prefix(8))...")
    }
    
    // Creates a URLRequest with the proper headers and authentication
    private func createRequest(_ endpoint: String, method: String = "GET") throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw CourtListenerAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = apiToken {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("Creating request for endpoint: \(endpoint)")
        print("URL: \(url)")
        print("Method: \(method)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        return request
    }
    
    // Validates a citation by checking it against CourtListener's database
    func validateCitation(_ citation: String) async throws -> [CitationResponse] {
        print("\nValidating citation: \(citation)")
        
        var request = try createRequest("citation-lookup/", method: "POST")
        let body = ["text": citation]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CourtListenerAPIError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decodedResponse = try JSONDecoder().decode([CitationResponse].self, from: data)
            print("Decoded response: \(decodedResponse)")
            return decodedResponse
        case 401:
            throw CourtListenerAPIError.unauthorized
        case 429:
            throw CourtListenerAPIError.rateLimitExceeded
        default:
            throw CourtListenerAPIError.invalidResponse
        }
    }
    
    // Searches for a case by its name
    func searchCaseName(_ caseName: String) async throws -> CaseSearchResponse {
        print("\nSearching case name: \(caseName)")
        
        let encodedName = caseName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? caseName
        let request = try createRequest("search/?type=o&case_name=\(encodedName)")
        
        print("Search URL: \(request.url?.absoluteString ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CourtListenerAPIError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decodedResponse = try JSONDecoder().decode(CaseSearchResponse.self, from: data)
            print("Decoded response: \(decodedResponse)")
            return decodedResponse
        case 401:
            throw CourtListenerAPIError.unauthorized
        case 429:
            throw CourtListenerAPIError.rateLimitExceeded
        default:
            throw CourtListenerAPIError.invalidResponse
        }
    }
    
    // Retrieves the full text of a court opinion
    func getOpinionText(clusterId: String) async throws -> OpinionResponse {
        print("\nGetting opinion text for cluster ID: \(clusterId)")
        
        let request = try createRequest("clusters/\(clusterId)/")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CourtListenerAPIError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decodedResponse = try JSONDecoder().decode(OpinionResponse.self, from: data)
            print("Decoded response: \(decodedResponse)")
            return decodedResponse
        case 401:
            throw CourtListenerAPIError.unauthorized
        case 429:
            throw CourtListenerAPIError.rateLimitExceeded
        default:
            throw CourtListenerAPIError.invalidResponse
        }
    }
}

// MARK: - Response Models

// Represents a response from the citation validation endpoint
struct CitationResponse: Codable {
    // The original citation that was validated
    let citation: String
    // Standardized versions of the citation
    let normalizedCitations: [String]
    // Where the citation starts in the input text
    let startIndex: Int
    // Where the citation ends in the input text
    let endIndex: Int
    // The HTTP status code from the API
    let status: Int
    // Any error message from the API
    let errorMessage: String
    // The matching cases found in CourtListener
    let clusters: [Cluster]
    
    enum CodingKeys: String, CodingKey {
        case citation
        case normalizedCitations = "normalized_citations"
        case startIndex = "start_index"
        case endIndex = "end_index"
        case status
        case errorMessage = "error_message"
        case clusters
    }
    
    var description: String {
        return "Citation: \(citation), Status: \(status), Clusters: \(clusters.count)"
    }
}

// Represents a response from the case search endpoint
struct CaseSearchResponse: Codable {
    // Total number of cases found
    let count: Int
    // The list of matching cases
    let results: [CaseResult]
    
    var description: String {
        return "Count: \(count), Results: \(results.count)"
    }
}

// Represents a single case result from a search
struct CaseResult: Codable {
    // The unique identifier for the case
    let id: Int
    // The name of the case
    let caseName: String
    // The citation for the case
    let citation: String
    // The URL to view the case on CourtListener
    let absoluteUrl: String
    // The cluster ID for the case
    let clusterId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case caseName = "case_name"
        case citation
        case absoluteUrl = "absolute_url"
        case clusterId = "cluster_id"
    }
    
    var description: String {
        return "ID: \(id), Case: \(caseName), Citation: \(citation)"
    }
}

// Represents a cluster (case) in CourtListener
struct Cluster: Codable {
    // The unique identifier for the case
    let id: Int
    // The name of the case
    let caseName: String
    // The URL to view the case on CourtListener
    let absoluteUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case caseName = "case_name"
        case absoluteUrl = "absolute_url"
    }
    
    // Converts the numeric ID to a string for storage
    var stringId: String {
        return String(id)
    }
    
    var description: String {
        return "ID: \(id), Case: \(caseName)"
    }
}

// Represents a response from the opinion text endpoint
struct OpinionResponse: Codable {
    // The unique identifier for the opinion
    let id: Int
    // The name of the case
    let caseName: String
    // The citation for the case
    let citation: String
    // The URL to view the case on CourtListener
    let absoluteUrl: String
    // The full text of the opinion
    let plainText: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case caseName = "case_name"
        case citation
        case absoluteUrl = "absolute_url"
        case plainText = "plain_text"
    }
    
    var description: String {
        return "ID: \(id), Case: \(caseName), Citation: \(citation)"
    }
} 