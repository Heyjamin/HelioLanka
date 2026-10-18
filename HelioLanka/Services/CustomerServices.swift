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
    
    func list(meterId: String, offset: Int = 0, limit: Int = 100) async throws -> [ReadingRow]{
        let encoded = meterId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? meterId
        let page: PageResult<ReadingRow> = try await client.request(
        "/api/v1/installations/\(encoded)/readings",
        query: [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: "timestampUtc"),
            URLQueryItem(name:"order", value: "desc")
            ]
        )
        return page.data
    }
    
    /// Newest intervals, several pages. Seed data is about three intervals per day,
    /// so five pages of 100 covers the 90 days the chart keeps.
    func listRecentHistory(meterId: String, pageSize: Int = 100, maxPages: Int = 5) async throws -> [ReadingRow]{
        var all: [ReadingRow] = []
        for page in 0..<maxPages{
            let batch = try await list (meterId: meterId, offset: page * pageSize, limit: pageSize)
            all.append(contentsOf: batch)
            if batch.count < pageSize { break }
        }
        return all
    }
}

actor WeatherService{
    private let client: APIClient
    
    init(client: APIClient){
        self.client = client
    }
    
    func forecast(meterId: String) async throws -> WeatherForecast {
        let encoded = meterId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? meterId
        return try await client.request("/api/v1/installations/\(encoded)/weather")
    }
}
