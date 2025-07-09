# Want - English Version

A conversational AI app that creates personalized chat experiences with AI personas. This is the English version of the original Japanese "want" app, featuring OpenAI integration for more natural conversations.

## Features

- 🤖 **AI-Powered Conversations**: Chat with AI personas using OpenAI GPT-4o-mini
- 👤 **Customizable Personas**: Create and customize AI personalities
- 💬 **Natural Conversations**: More natural and engaging chat experiences
- 🎭 **Emotion Awareness**: AI responds to emotional context
- 📱 **Modern iOS UI**: Beautiful SwiftUI interface
- 🔒 **Privacy Focused**: Local data storage and secure API communication
- 💳 **Subscription Model**: Premium features with subscription support

## Technology Stack

### iOS App
- **Framework**: SwiftUI
- **Language**: Swift
- **Target**: iOS 18.5+
- **AI Provider**: OpenAI GPT-4o-mini

### Backend Server
- **Platform**: Vercel
- **Runtime**: Node.js
- **API**: OpenAI API
- **CORS**: Enabled for iOS app

## Setup Instructions

### 1. iOS App Setup

1. Clone the repository:
```bash
git clone https://github.com/tegujupe222/want-en.git
cd want-en
```

2. Open the project in Xcode:
```bash
open want_EN.xcodeproj
```

3. Build and run on iOS Simulator or device

### 2. Vercel Server Setup

1. Navigate to the server directory:
```bash
cd vercel-server
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
   - Create a `.env.local` file
   - Add your OpenAI API key: `OPENAI_API_KEY=your_key_here`

4. Deploy to Vercel:
```bash
npm i -g vercel
vercel login
vercel
```

5. Update the iOS app with your Vercel URL:
   - Open `AIConfigManager.swift`
   - Update `cloudFunctionURL` with your Vercel deployment URL

## Project Structure

```
want_EN/
├── want_EN/                    # Main iOS app
│   ├── wantApp.swift          # App entry point
│   ├── ContentView.swift      # Main content view
│   ├── ChatView.swift         # Chat interface
│   ├── ChatRoomListView.swift # Chat room list
│   ├── PersonaListView.swift  # Persona management
│   ├── SettingsView.swift     # App settings
│   ├── AIChatService.swift    # AI service layer
│   ├── OpenAIAPIService.swift # OpenAI integration
│   ├── AIConfigManager.swift  # AI configuration
│   └── ...                    # Other Swift files
├── vercel-server/             # Backend server
│   ├── api/
│   │   └── chat.js           # Main API endpoint
│   ├── package.json          # Node.js dependencies
│   ├── vercel.json          # Vercel configuration
│   └── README.md            # Server setup guide
└── README.md                # This file
```

## API Endpoints

### POST /api/chat

Handles AI conversation requests from the iOS app.

**Request Body:**
```json
{
  "persona": {
    "name": "Assistant Name",
    "relationship": "Friend",
    "personality": ["Friendly", "Helpful"],
    "speechStyle": "Casual and warm",
    "catchphrases": ["Hello!", "How can I help?"],
    "favoriteTopics": ["Technology", "Science"]
  },
  "conversationHistory": [...],
  "userMessage": "How are you today?",
  "emotionContext": "Happy and excited"
}
```

**Response:**
```json
{
  "response": "Hello! I'm doing great today, thanks for asking! How about you?",
  "error": null
}
```

## Configuration

### AI Settings

The app supports multiple AI providers:
- **OpenAI GPT**: Default provider for natural conversations
- **Google Gemini**: Alternative provider (legacy support)

### Environment Variables

Required for the Vercel server:
- `OPENAI_API_KEY`: Your OpenAI API key

## Development

### Building the iOS App

```bash
cd want_EN
xcodebuild -project want_EN.xcodeproj -scheme want_EN -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Running the Server Locally

```bash
cd vercel-server
npm run dev
```

## Deployment

### iOS App
- Archive and upload to App Store Connect
- Configure app signing and provisioning profiles
- Set up App Store metadata and screenshots

### Vercel Server
- Automatic deployment on git push
- Environment variables configured in Vercel dashboard
- Custom domain setup (optional)

## Security Considerations

- API keys stored securely in Vercel environment variables
- CORS configured for iOS app domain
- Input validation and sanitization
- Rate limiting protection
- Error handling without exposing sensitive information

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation in the `vercel-server/README.md`
- Review the code comments for implementation details

## Changelog

### Version 1.0.0 (English Release)
- ✅ Complete English translation
- ✅ OpenAI integration replacing Gemini
- ✅ Vercel server deployment
- ✅ Enhanced conversation naturalness
- ✅ Improved error handling
- ✅ Updated UI text and comments
- ✅ Comprehensive documentation 