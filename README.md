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

(c) 2025 Tucuxi, Inc.

This project is licensed under the following terms:

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The above copyright notice, permission notice and disclaimer of warranty must be included in all copies or substantial portions of the Software that you use or distribute.

Additional Terms:

Given that this Software is being made available for free, access to, review of, or use of the code by you (or if you are acting as the agent of any other party - their use) is subject to the additional following terms:

You covenant that you will not (nor will you act on behalf of another party to gather information or assist in taking action to) assert against Tucuxi, Inc. its affiliates, officers, employees, directors, and agents a claim of direct or indirect patent infringement arising from the manufacture, sale, import, use, distribution or other disposal of the Software.  You expressly waive (on your own behalf and will obtain waiver from anyone on whose behalf you act) any right to seek, obtain or enforce any injunction to directly or indirectly prevent or interfere with Tucuxi’s direct or indirect manufacture, use, import, sale, distribution or other disposal of the Software, whether for an intellectual property rights claim, or under any other theory at law or in equity. 

You agree (on your behalf and will obtain the same agreement from any party on whose behalf you act (with Tucuxi, Inc. being an express third party beneficiary to such agreement) to release, indemnify, and hold Tucuxi, Inc., its affiliates, officers, employees, directors, and agents harmless from any and all losses, damages, fines, penalties, fees, costs and expenses, including reasonable attorneys’ fees, claims, actions of any kind, and injury (including death) arising out of or relating to your (or their) use or distribution of the Software or your failure (if acting on behalf of another party) to obtain their agreement to these Additional Terms before sharing this Software or any information about it with them.

If you breach the Additional Terms, the licenses granted above will immediately terminate,  but these Additional Terms will survive any termination of the license.




## Acknowledgments

- [CourtListener](https://www.courtlistener.com) for providing the API
- Apple for SwiftUI and SwiftData frameworks 
