//
//  ContentView.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-11.
//

import SwiftUI

struct ContentView: View {
    
    @State private var statusText = "Checking API.."
    @State private var isOK = false
    
    var body: some View {
        
        ZStack {
            HelioBackground()
            
            VStack(spacing:16){
                Text("HelioLanka")
                    .font(.system(size:40, weight:.bold, design:.rounded))
                    .foregroundStyle(HelioTheme.navy)
                
                Text ("Your rooftop solar, elevated.")
                    .font(.title3)
                    .foregroundStyle(HelioTheme.inkMuted)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8){
                    Text ("API base")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HelioTheme.ocean)
                    
                    Text(AppEnvironment.apiBaseURL.absoluteString)
                        .font(.footnote.monospaced())
                        .foregroundStyle(HelioTheme.navy)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    
                    Text(statusText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isOK ? HelioTheme.leaf : HelioTheme.navy)
                        .padding(.top, 8)
                }
                .padding(HelioTheme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: HelioTheme.cardRadius, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                )
                .padding(.top, 24)
                
                Button ("Retry connection"){
                    Task { await checkAPI() }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(HelioTheme.ctaGradient)
                .clipShape(RoundedRectangle(cornerRadius: HelioTheme.controlRadius, style: .continuous))
            }
            .padding(HelioTheme.screenPadding)
        }
        .task {
            await checkAPI()
        }
    }
    
    @MainActor
    private func checkAPI() async {
        statusText = "Checking API.."
        isOK = false
        do {
            // Public health check - no auth.
            let _: HealthResponse = try await APIClient.shared.request(
                "/health",
                method: .get,
                auth: false
            )
            statusText = "API reachable - Phase 02 complete"
            isOK = true
        } catch {
            // If /health shape differes, still prove transport worksvia raw status.
            do {
                let data = try await APIClient.shared.rawRequest(
                    "/health",
                    method: .get,
                    auth: false
                )
                let preview = String(data: data, encoding: .utf8) ?? "(binary)"
                statusText = "API responded (\(preview.prefix(80))) - Phase 02 complete"
                isOK = true
            } catch {
                statusText = error.localizedDescription
                isOK = false
            }
        }
    }
}

/// Minimal decode target for health JSON.
private struct HealthResponse: Decodable{
    var status: String?
}

#Preview {
    ContentView()
}
