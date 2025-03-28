import SwiftUI
import SafariServices

// A view that displays detailed information about a citation
// This includes the citation text, case name, validation status,
// and links to view the case on CourtListener
struct CitationResultView: View {
    // The citation to display details for
    let citation: Citation
    // Whether the opinion text sheet is shown
    @State private var showingOpinionText = false
    // Whether the web view sheet is shown
    @State private var showingWebView = false
    // Whether the notes sheet is shown
    @State private var showingNotes = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Citation text and normalized version
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
            
            // Status badges for citation and case name validation
            HStack {
                StatusBadge(title: "Citation", status: citation.citationStatus)
                StatusBadge(title: "Case Name", status: citation.caseNameStatus)
            }
            
            // Case name if available
            if let caseName = citation.caseName {
                Text(caseName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Action buttons for viewing opinion, case, and notes
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
                
                if citation.notes != nil {
                    Button(action: { showingNotes = true }) {
                        Label("View Details", systemImage: "info.circle")
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        // Sheet to display the opinion text
        .sheet(isPresented: $showingOpinionText) {
            if let opinionText = citation.opinionText {
                OpinionTextView(text: opinionText)
            }
        }
        // Sheet to display the CourtListener webpage
        .sheet(isPresented: $showingWebView) {
            if let urlString = citation.courtListenerUrl,
               let url = URL(string: urlString) {
                SafariView(url: url)
            }
        }
        // Sheet to display the notes
        .sheet(isPresented: $showingNotes) {
            if let notes = citation.notes {
                NotesView(text: notes)
            }
        }
    }
}

// A view that displays a status badge with appropriate colors
// Used to show whether a citation or case name is valid or invalid
struct StatusBadge: View {
    // The title of the badge (e.g., "Citation" or "Case Name")
    let title: String
    // The status to display
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
    
    // The background color for the badge based on the status
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

// A protocol that both CitationStatus and CaseNameStatus conform to
// This allows the StatusBadge view to handle both types of status
protocol StatusType: RawRepresentable where RawValue == String {}
extension CitationStatus: StatusType {}
extension CaseNameStatus: StatusType {}

// A view that displays the full text of a court opinion
struct OpinionTextView: View {
    // The text of the opinion to display
    let text: String
    // Environment variable to dismiss the sheet
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

// A view that displays additional notes about a citation
struct NotesView: View {
    // The notes text to display
    let text: String
    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
                    .padding()
            }
            .navigationTitle("Case Details")
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

// A view that displays a web page using SafariServices
// This is used to show the CourtListener website within the app
struct SafariView: UIViewControllerRepresentable {
    // The URL to display
    let url: URL
    
    // Creates the Safari view controller
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    // Updates the Safari view controller (not needed in this case)
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
} 