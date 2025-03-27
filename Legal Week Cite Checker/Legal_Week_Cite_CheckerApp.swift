//
//  Legal_Week_Cite_CheckerApp.swift
//  Legal Week Cite Checker
//
//  Created by Kevin Keller on 3/26/25.
//

import SwiftUI
import SwiftData

// The main entry point of the app
// This struct sets up the app's environment and initializes necessary services
@main
struct Legal_Week_Cite_CheckerApp: App {
    // The shared SwiftData model container that persists data across app launches
    var sharedModelContainer: ModelContainer = {
        // Define the schema for our data models
        let schema = Schema([
            Citation.self,
        ])
        // Configure the model to store data persistently
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // The citation service that handles citation validation
    @StateObject private var citationService: CitationService
    
    // Initialize the app and set up required services
    init() {
        // Create a model container for SwiftData
        let container = try! ModelContainer(for: Citation.self)
        // Initialize the citation service with the model context
        _citationService = StateObject(wrappedValue: CitationService(modelContext: container.mainContext))
        
        // If an API token exists, set it up for the CourtListener API
        if let token = try? SecureStorageService.shared.getAPIToken() {
            Task {
                await CourtListenerAPI.shared.setAPIToken(token)
            }
        }
    }

    // The main view hierarchy of the app
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(citationService)
        }
        .modelContainer(sharedModelContainer)
    }
}
