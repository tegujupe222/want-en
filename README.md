# Want EN - Vercel Server

This is the Vercel serverless backend for the Want EN iOS app, providing a secure proxy for Google Gemini API calls.

## Setup

1. **Deploy to Vercel**
   ```bash
   vercel --prod
   ```

2. **Set Environment Variables**
   - Go to your Vercel dashboard
   - Navigate to Settings > Environment Variables
   - Add `GEMINI_API_KEY` with your Google Gemini API key

3. **Get Your API Endpoint**
   - After deployment, you'll get a URL like: `https://your-project.vercel.app`
   - Your Gemini proxy endpoint will be: `https://your-project.vercel.app/api/gemini-proxy`

## API Endpoint

### POST /api/gemini-proxy

**Request Body:**
```json
{
  "prompt": "User's message",
  "persona": {
    "name": "Persona name",
    "relationship": "Relationship to user",
    "personality": "Personality description",
    "speechStyle": "Speech style"
  },
  "conversationHistory": [
    {
      "isUser": true,
      "content": "User message"
    },
    {
      "isUser": false,
      "content": "Assistant response"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "response": "AI generated response",
  "model": "gemini-2.0-flash-exp"
}
```

## Features

- ✅ Secure API key management via environment variables
- ✅ CORS enabled for cross-origin requests
- ✅ Persona-based conversation context
- ✅ Conversation history support
- ✅ Error handling for API limits and safety filters
- ✅ Uses Gemini 2.5 Flash Lite model

## Local Development

```bash
npm install
vercel dev
```

## Deployment

```bash
vercel --prod
```
