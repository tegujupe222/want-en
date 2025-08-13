# Want-EN Vercel Server

This is the Vercel server for the Want-EN iOS app, providing a proxy for Gemini API calls.

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Variables

Set up the following environment variable in Vercel:

- `GEMINI_API_KEY`: Your Google Gemini API key

### 3. Deploy to Vercel

```bash
npm run deploy
```

## API Endpoints

### POST /api/gemini-proxy

Generates AI responses using Google's Gemini 2.5 Flash Lite model.

**Request Body:**
```json
{
  "prompt": "User's message",
  "persona": {
    "name": "Persona name",
    "relationship": "Relationship to user",
    "personality": "Personality traits",
    "communicationStyle": "How they communicate",
    "interests": "Their interests",
    "background": "Background information"
  },
  "conversationHistory": [
    {
      "isFromUser": true,
      "content": "Previous user message"
    },
    {
      "isFromUser": false,
      "content": "Previous assistant response"
    }
  ]
}
```

**Response:**
```json
{
  "response": "AI generated response",
  "model": "gemini-2.0-flash-exp",
  "timestamp": "2025-01-01T00:00:00.000Z"
}
```

## Environment Variables Setup in Vercel

1. Go to your Vercel project dashboard
2. Navigate to Settings > Environment Variables
3. Add the following variable:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Your Google Gemini API key
   - **Environment**: Production, Preview, Development

## Local Development

```bash
npm run dev
```

The server will be available at `http://localhost:3000/api/gemini-proxy`
# Updated at 2025年 8月13日 水曜日 09時08分34秒 JST
