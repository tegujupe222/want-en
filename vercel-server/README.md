# Want AI Server

This is the Vercel server for the Want AI iOS app, providing OpenAI integration for natural conversations.

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Variables

Create a `.env.local` file in the root directory:

```env
OPENAI_API_KEY=your_openai_api_key_here
```

### 3. Local Development

```bash
npm run dev
```

### 4. Deploy to Vercel

1. Install Vercel CLI:
```bash
npm i -g vercel
```

2. Login to Vercel:
```bash
vercel login
```

3. Deploy:
```bash
vercel
```

4. Set environment variables in Vercel dashboard:
   - Go to your project settings
   - Add `OPENAI_API_KEY` with your OpenAI API key

### 5. Update iOS App

After deployment, update the `cloudFunctionURL` in your iOS app's `AIConfigManager.swift`:

```swift
cloudFunctionURL: "https://your-vercel-app.vercel.app/api/chat"
```

## API Endpoint

- **URL**: `/api/chat`
- **Method**: `POST`
- **Content-Type**: `application/json`

### Request Body

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
  "conversationHistory": [
    {
      "content": "Hello!",
      "isUser": true,
      "timestamp": "2024-01-01T00:00:00Z"
    }
  ],
  "userMessage": "How are you today?",
  "emotionContext": "Happy and excited"
}
```

### Response

```json
{
  "response": "Hello! I'm doing great today, thanks for asking! How about you?",
  "error": null
}
```

## Features

- ✅ OpenAI GPT-4o-mini integration
- ✅ Persona-based conversations
- ✅ Conversation history support
- ✅ Emotion context awareness
- ✅ CORS support for iOS app
- ✅ Error handling and validation
- ✅ Rate limiting protection

## Security Notes

- In production, restrict CORS origins to your app's domain
- Keep your OpenAI API key secure
- Monitor API usage and costs
- Consider implementing rate limiting per user 