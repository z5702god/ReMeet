# Re:Meet

> Business card management iOS app with AI-powered context recording

[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)

## 📱 Features

- **📸 Business Card Scanning**: Capture multiple business cards with OCR technology
- **🤖 AI-Powered Context Recording**: Automatically record meeting context (time, location, topics)
- **🏢 Company Classification**: Organize contacts by company
- **📅 Timeline View**: Browse contacts chronologically like a photo album
- **🔍 Smart Search**: Find contacts by name, company, or meeting context
- **💬 AI Chat Assistant**: Natural language queries about your contacts

## 🛠 Tech Stack

### Frontend
- **Swift** & **SwiftUI** - Native iOS development
- **AVFoundation** - Camera and image processing
- **MVVM Architecture** - Clean, maintainable code structure

### Backend
- **Supabase** - PostgreSQL database with real-time capabilities
- **Supabase Storage** - Secure business card image storage
- **Row Level Security (RLS)** - Data protection
- **n8n** - Workflow automation for OCR and AI processing

### AI & Processing
- **Google Vision API / AWS Textract** - OCR for business cards
- **OpenAI GPT-4** - AI assistant and context extraction

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode 14.0+
- iOS 15.0+ device or simulator
- Supabase account
- Apple Developer account (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ReMeet.git
   cd ReMeet
   ```

2. **Set up Supabase**
   - Follow the guide in [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
   - Run the SQL schema: [supabase-schema.sql](supabase-schema.sql)
   - Set up storage policies: [storage-policies.sql](storage-policies.sql)

3. **Configure the iOS app**
   - Open Xcode and create a new project named "ReMeet"
   - Follow [iOS_PROJECT_SETUP.md](iOS_PROJECT_SETUP.md) for detailed setup
   - Add Supabase Swift SDK via Swift Package Manager:
     ```
     https://github.com/supabase-community/supabase-swift
     ```

4. **Add your Supabase credentials**

   In your `Info.plist`:
   ```xml
   <key>SUPABASE_URL</key>
   <string>https://your-project-ref.supabase.co</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>your-anon-key-here</string>
   ```

5. **Run the app**
   - Select a simulator or connected device
   - Press `⌘R` to build and run

## 📂 Project Structure

```
ReMeet/
├── ios/ReMeet/              # iOS app source code
│   ├── App/                 # App entry point
│   ├── Core/                # Core functionality
│   │   ├── Config/          # Configuration
│   │   ├── Network/         # API clients
│   │   └── Models/          # Data models
│   ├── Features/            # Feature modules
│   │   ├── Authentication/  # Login, register
│   │   ├── Home/            # Contact list
│   │   ├── Camera/          # Card scanning
│   │   ├── Chat/            # AI assistant
│   │   └── ...
│   └── Shared/              # Reusable components
├── .claude/                 # Claude AI skills
├── supabase-schema.sql      # Database schema
├── storage-policies.sql     # Storage RLS policies
└── docs/                    # Documentation
```

## 📖 Documentation

- [PRD.md](PRD.md) - Product Requirements Document
- [iOS_PROJECT_SETUP.md](iOS_PROJECT_SETUP.md) - iOS setup guide
- [SUPABASE_SETUP.md](SUPABASE_SETUP.md) - Backend setup
- [AUTHENTICATION_SETUP.md](AUTHENTICATION_SETUP.md) - Auth configuration
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - Development progress
- [ios/README.md](ios/README.md) - iOS code documentation

## 🗺 Roadmap

### Phase 1: MVP (2-3 weeks) ✅
- [x] Authentication system
- [x] Basic UI structure
- [x] Supabase integration
- [ ] Manual contact entry
- [ ] Camera functionality

### Phase 2: OCR Integration (3-4 weeks)
- [ ] n8n workflow setup
- [ ] OCR processing pipeline
- [ ] Edit OCR results

### Phase 3: AI Features (4-5 weeks)
- [ ] AI chat interface
- [ ] Context extraction
- [ ] Smart search

### Phase 4: Polish (3-4 weeks)
- [ ] Company management
- [ ] Timeline view
- [ ] Performance optimization
- [ ] Testing

## 🔐 Security

- All API keys stored in `Info.plist` (not committed to git)
- Row Level Security (RLS) enabled on all Supabase tables
- User data isolated with UUID-based policies
- Secure image storage with access control

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Supabase](https://supabase.com/)
- OCR powered by Google Vision API / AWS Textract
- AI assistance by OpenAI GPT-4
- Workflow automation by [n8n](https://n8n.io/)

## 📧 Contact

Project Link: [https://github.com/YOUR_USERNAME/ReMeet](https://github.com/YOUR_USERNAME/ReMeet)

---

**Status**: In Development (50% complete)
**Last Updated**: 2026-01-11
**Version**: 1.0.0-alpha
