//
//  Legal_Week_Cite_CheckerApp.swift
//  Legal Week Cite Checker
//
//  Created by Kevin Keller on 3/26/25.
//

import SwiftUI
import SwiftData

@main
struct Legal_Week_Cite_CheckerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Citation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var citationService: CitationService
    
    init() {
        let container = try! ModelContainer(for: Citation.self)
        _citationService = StateObject(wrappedValue: CitationService(modelContext: container.mainContext))
        
        // Initialize API token if available
        if let token = try? SecureStorageService.shared.getAPIToken() {
            Task {
                await CourtListenerAPI.shared.setAPIToken(token)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(citationService)
        }
        .modelContainer(sharedModelContainer)
    }
}
