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
    let modelContainer: ModelContainer
    
    // The citation service that handles citation validation
    @StateObject private var citationService: CitationService
    
    // Initialize the app and set up required services
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false
    
    init() {
        do {
            // Create a model container for SwiftData
            modelContainer = try ModelContainer(for: Citation.self)
            
            // Initialize the citation service with the model context
            let service = CitationService(modelContext: modelContainer.mainContext)
            _citationService = StateObject(wrappedValue: service)
            
            // Set up the API token if it exists
            if let token = try? SecureStorageService.shared.getAPIToken() {
                Task { @MainActor in
                    await CourtListenerAPI.shared.setAPIToken(token)
                }
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    // The main view hierarchy of the app
    var body: some Scene {
        WindowGroup {
            if !hasCompletedWelcome {
                WelcomeView()
            } else {
                ContentView()
                    .environmentObject(citationService)
            }
        }
        .modelContainer(modelContainer)
    }
}
