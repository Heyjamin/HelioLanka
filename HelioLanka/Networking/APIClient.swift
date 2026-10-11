//
//  APIClient.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case http(status: Int, message:String)
    case decoding(Error)
    case transport(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Internal server error, please try again later."
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .http(_, let message):
            return message
        case .decoding:
            return "Internal server error, please try again later."
        case .transport:
            return "Internal server error, please try again later."
        }
    }
}


struct APIErrorBody: Decodable {
    let message: String?
    let description: String?
}

struct EmptyResponse: Decodable {}

/// In-memory token holder for Phase 02. Replaces/extended by Keychain in phase 03.
actor APIClient{
    static let shared = APIClient()
    
    private let baseURL: URL
    private let session: URLSession
    private var accessToken: String?
    private var refreshToken: String?
    
    init(baseURL: URL = AppEnvironment.apiBaseURL){
        self.baseURL = baseURL
        self.session = URLSession(configuration: .default)
    }
    
    func setTokens(access: String?, refresh: String?){
        accessToken = access
        refreshToken = refresh
    }
    
    func clearTokens(){
        accessToken = nil
        refreshToken = nil
    }
    
    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        auth: Bool = true,
        query: [URLQueryItem] = []
    ) async throws -> T {
        let data = try await rawRequest(path, method: method, body: body, auth: auth, query: query)
        
        if T.self == EmptyResponse.self{
            return EmptyResponse() as! T
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)
                
                let withFrac = ISO8601DateFormatter()
                withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = withFrac.date(from: str){ return d }
                
                let basic = ISO8601DateFormatter()
                basic.formatOptions = [.withInternetDateTime]
                if let d = basic.date(from: str) { return d }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Bad date \(str)"
                )
            }
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
    
    func rawRequest(
        _ path: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        auth: Bool = true,
        query: [URLQueryItem] = []
    ) async throws -> Data {
        let urlString =
        baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        + "/"
        + path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard var comps = URLComponents(string: urlString) else{
            throw APIError.invalidURL
        }
        
        if !query.isEmpty {
            comps.queryItems = query
        }
        guard let url = comps.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if auth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField:"Authorization")
        }
        
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        
        let (data,response): (Data, URLResponse)
        do{
            (data,response) = try await session.data(for: request)
        }catch{
            throw APIError.transport(error)
        }
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, message: "No HTTP response")
        }
        
        if http.statusCode == 204{
            return Data()
        }
        
        if !(200..<300).contains(http.statusCode){
            let parsed = try? JSONDecoder().decode(APIErrorBody.self, from: data)
            let serverMessage = [parsed?.message, parsed?.description]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines)}
                .first {!$0.isEmpty}
            
            if http.statusCode == 401, auth {
                throw APIError.unauthorized
            }
            if http.statusCode == 401{
                throw APIError.http(
                    status: 401,
                    message: serverMessage ?? "Username of Password incorrect. Please try again."
                )
            }
            
            throw APIError.http(
                status: http.statusCode,
                message: serverMessage
                ?? String(data: data, encoding: .utf8)
                ?? "HTTP \(http.statusCode)"
            )
        }
        return data
        
    }
}
    
    /// Helps encode `any Encodable` request bodies.
    private struct AnyEncodable: Encodable {
        private let encodeFunc: (Encoder) throws -> Void
        
        init(_ value: any Encodable){
            encodeFunc = { encoder in try value.encode(to: encoder)}
        }
        
        func encode (to encoder: Encoder) throws {
            try encodeFunc(encoder)
        }
    }

