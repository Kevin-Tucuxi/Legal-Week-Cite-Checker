import SwiftUI

struct APITokenView: View {
    @State private var apiToken: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isTokenValid = false
    
    var body: some View {
        Form {
            Section(header: Text("CourtListener API Token")) {
                SecureField("Enter your API token", text: $apiToken)
                    .textContentType(.password)
                
                Button(action: saveToken) {
                    Text("Save Token")
                        .frame(maxWidth: .infinity)
                }
                .disabled(apiToken.isEmpty)
                
                if isTokenValid {
                    Button(action: deleteToken) {
                        Text("Delete Token")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .alert("API Token", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            checkTokenStatus()
        }
    }
    
    private func saveToken() {
        do {
            try SecureStorageService.shared.saveAPIToken(apiToken)
            Task {
                await CourtListenerAPI.shared.setAPIToken(apiToken)
                isTokenValid = true
                alertMessage = "API token saved successfully"
                showingAlert = true
            }
        } catch {
            alertMessage = "Failed to save API token: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteToken() {
        do {
            try SecureStorageService.shared.deleteAPIToken()
            apiToken = ""
            isTokenValid = false
            alertMessage = "API token deleted successfully"
        } catch {
            alertMessage = "Failed to delete API token: \(error.localizedDescription)"
        }
        showingAlert = true
    }
    
    private func checkTokenStatus() {
        isTokenValid = SecureStorageService.shared.hasAPIToken()
    }
} 