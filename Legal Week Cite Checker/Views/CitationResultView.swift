import SwiftUI
import SafariServices

struct CitationResultView: View {
    let citation: Citation
    @State private var showingOpinionText = false
    @State private var showingWebView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(citation.originalText)
                    .font(.headline)
                Spacer()
                if let normalizedCitation = citation.normalizedCitation {
                    Text(normalizedCitation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                StatusBadge(title: "Citation", status: citation.citationStatus)
                StatusBadge(title: "Case Name", status: citation.caseNameStatus)
            }
            
            if let caseName = citation.caseName {
                Text(caseName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if citation.opinionText != nil {
                    Button(action: { showingOpinionText = true }) {
                        Label("View Opinion", systemImage: "doc.text")
                    }
                }
                
                if citation.courtListenerUrl != nil {
                    Button(action: { showingWebView = true }) {
                        Label("View on CourtListener", systemImage: "link")
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .sheet(isPresented: $showingOpinionText) {
            if let opinionText = citation.opinionText {
                OpinionTextView(text: opinionText)
            }
        }
        .sheet(isPresented: $showingWebView) {
            if let urlString = citation.courtListenerUrl,
               let url = URL(string: urlString) {
                SafariView(url: url)
            }
        }
    }
}

struct StatusBadge: View {
    let title: String
    let status: any StatusType
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
            Text(status.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    private var statusColor: Color {
        switch status.rawValue {
        case "valid":
            return .green
        case "invalid":
            return .red
        default:
            return .gray
        }
    }
}

protocol StatusType: RawRepresentable where RawValue == String {}
extension CitationStatus: StatusType {}
extension CaseNameStatus: StatusType {}

struct OpinionTextView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
                    .padding()
            }
            .navigationTitle("Opinion Text")
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

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
} 