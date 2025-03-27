import Foundation

enum CourtListenerAPIError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case unauthorized
    case rateLimitExceeded
    case unknown(Error)
}

actor CourtListenerAPI {
    private let baseURL = "https://www.courtlistener.com/api/rest/v4"
    private var apiToken: String?
    
    static let shared = CourtListenerAPI()
    
    private init() {}
    
    func setAPIToken(_ token: String) {
        self.apiToken = token
        print("API Token set: \(token.prefix(8))...")
    }
    
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

// Response Models
struct CitationResponse: Codable {
    let citation: String
    let normalizedCitations: [String]
    let startIndex: Int
    let endIndex: Int
    let status: Int
    let errorMessage: String
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

struct CaseSearchResponse: Codable {
    let count: Int
    let results: [CaseResult]
    
    var description: String {
        return "Count: \(count), Results: \(results.count)"
    }
}

struct CaseResult: Codable {
    let id: Int
    let caseName: String
    let citation: String
    let absoluteUrl: String
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

struct OpinionResponse: Codable {
    let id: Int
    let caseName: String
    let citation: String
    let absoluteUrl: String
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

struct Cluster: Codable {
    let id: Int
    let caseName: String
    let absoluteUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case caseName = "case_name"
        case absoluteUrl = "absolute_url"
    }
    
    var stringId: String {
        return String(id)
    }
    
    var description: String {
        return "ID: \(id), Case: \(caseName)"
    }
} 