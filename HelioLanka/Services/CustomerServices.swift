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

actor ProfileService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func get() async throws -> CustomerProfile {
        try await client.request("/api/v1/customers/me/profile")
    }

    func update(_ body: UpdateProfileBody) async throws -> CustomerProfile {
        try await client.request(
            "/api/v1/customers/me/profile",
            method: .patch,
            body: body
        )
    }

    func linkAccount(_ accountNumber: String) async throws -> UserMe {
        try await client.request(
            "/api/v1/auth/link-account",
            method: .post,
            body: LinkAccountBody(accountNumber: accountNumber)
        )
    }
}

actor LeaderboardService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetch(period: String) async throws -> [LeaderboardEntry] {
        let response: LeaderboardResponse = try await client.request(
            "/api/v1/leaderboard",
            auth: false,
            query: [
                URLQueryItem(name: "period", value: period),
                URLQueryItem(name: "limit", value: "50")
            ]
        )
        return response.entries
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
