import SwiftUI
import PDFKit

struct WelcomeView: View {
    @State private var hasReadTerms = false
    @State private var showingTerms = false
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Legal Citation Checker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Text("By clicking 'Get Started' below, you agree to the")
                    .multilineTextAlignment(.center)
                Text("Terms of Use")
                    .foregroundColor(.blue)
                    .underline()
                    .onTapGesture {
                        showingTerms = true
                    }
            }
            .multilineTextAlignment(.center)
            
            Button(action: {
                if hasReadTerms {
                    // Navigate to main app
                    UserDefaults.standard.set(true, forKey: "hasCompletedWelcome")
                } else {
                    showingAlert = true
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(hasReadTerms ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!hasReadTerms)
        }
        .padding()
        .sheet(isPresented: $showingTerms) {
            PDFViewer(pdfName: "NYCLW2025CitationCheckerTermsOfUse")
                .onDisappear {
                    hasReadTerms = true
                }
        }
        .alert("Please Read the Terms of Use to Proceed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct PDFViewer: View {
    let pdfName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PDFKitView(pdfName: pdfName)
                .navigationTitle("Terms of Use")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfName: String
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        
        if let path = Bundle.main.path(forResource: pdfName, ofType: "pdf"),
           let document = PDFDocument(url: URL(fileURLWithPath: path)) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

#Preview {
    WelcomeView()
} 