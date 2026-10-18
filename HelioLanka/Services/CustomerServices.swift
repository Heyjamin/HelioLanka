//
//  CustomerServices.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-18.
//

import Foundation

actor InstallationService{
    private let client: APIClient
    
    init (client: APIClient){
        self.client = client
    }
    
    func composite(meterId: String) async throws -> InstallationComposite {
        let encoded = meterId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? meterId
        return try await client.request("/api/v1/installations/\(encoded)/composite")
    }
}

actor ReadingService {
    private let client: APIClient
    
    init(client: APIClient){
        self.client = client
    }
    
    /// Newest intervals first. One page is enogh for Home
    func latest(meterId: String, limit: Int = 100) async throws -> [ReadingRow]{
        let encoded = meterId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? meterId
        let page: PageResult<ReadingRow> = try await client.request(
        "/api/v1/installations/\(encoded)/readings",
        query: [
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: "timestampUtc"),
            URLQueryItem(name:"order", value: "desc")
            ]
        )
        return page.data
    }
}
