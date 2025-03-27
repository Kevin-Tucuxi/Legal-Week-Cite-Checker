# Legal Week Cite Checker

A SwiftUI app for validating legal citations using the CourtListener API. This app helps legal professionals and researchers quickly verify citations and access case information.

## Features

- Validate legal citations against the CourtListener database
- Extract and validate case names from citations
- View case details including case name, citation, and opinion text
- Direct links to full case documents on CourtListener
- Modern SwiftUI interface following Apple's Human Interface Guidelines
- SwiftData persistence for citation history

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- CourtListener API Token

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/LegalWeekCiteChecker.git
```

2. Open the project in Xcode:
```bash
cd LegalWeekCiteChecker
open "Legal Week Cite Checker.xcodeproj"
```

3. Get a CourtListener API token:
   - Visit [CourtListener](https://www.courtlistener.com)
   - Create an account or sign in
   - Navigate to your profile settings
   - Generate an API token

4. Add your API token to the app:
   - Launch the app
   - Enter your API token in the settings

## Usage

1. Launch the app
2. Enter a legal citation (e.g., "347 U.S. 483")
3. The app will:
   - Validate the citation against CourtListener
   - Extract and validate the case name
   - Display case details if found
   - Provide a link to the full case document

## Architecture

The app is built using:
- SwiftUI for the user interface
- SwiftData for persistence
- MVVM architecture pattern
- Actor-based API client for thread safety

### Key Components

- `Citation`: Data model for storing citation information
- `CourtListenerAPI`: Actor-based API client for CourtListener
- `CitationService`: Service layer for citation validation
- `ContentView`: Main view of the application
- `CitationResultView`: Detailed view for citation results

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [CourtListener](https://www.courtlistener.com) for providing the API
- Apple for SwiftUI and SwiftData frameworks 
