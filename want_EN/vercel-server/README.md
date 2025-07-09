# want_EN Vercel Server

This is the Vercel server component for the want_EN AI chat app. It provides a proxy API endpoint for OpenAI integration.

## 🚀 Quick Setup

### 1. Deploy to Vercel

1. **Install Vercel CLI** (if not already installed):
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel**:
   ```bash
   vercel login
   ```

3. **Deploy the server**:
   ```bash
   cd vercel-server
   vercel --prod
   ```

4. **Set up environment variables**:
   - Go to your Vercel dashboard
   - Navigate to your project settings
   - Add the following environment variable:
     - `OPENAI_API_KEY`: Your OpenAI API key

### 2. Update Swift App Configuration

After deployment, update the `AIConfigManager.swift` in your Swift app:

```swift
// Replace the default URL with your actual Vercel deployment URL
cloudFunctionURL: "https://your-vercel-app.vercel.app/api/openai-proxy"
```

## 📁 Project Structure

```
vercel-server/
├── api/
│   └── openai-proxy.js    # Main API endpoint
├── package.json           # Dependencies
└── README.md             # This file
```

## 🔧 API Endpoint

### POST `/api/openai-proxy`

**Request Body:**
```json
{
  "persona": {
    "name": "Assistant Name",
    "relationship": "Friend",
    "personality": ["Friendly", "Helpful"],
    "speechStyle": "Casual",
    "catchphrases": ["Hello!", "How can I help?"],
    "favoriteTopics": ["Technology", "Science"]
  },
  "conversationHistory": [
    {
      "content": "Hello!",
      "isFromUser": true,
      "timestamp": "2024-01-01T00:00:00Z"
    }
  ],
  "userMessage": "How are you today?",
  "emotionContext": "Happy"
}
```

**Response:**
```json
{
  "response": "I'm doing great! Thanks for asking. How about you?",
  "error": null
}
```

## 🛠️ Development

### Local Development

1. **Install dependencies**:
   ```bash
   cd vercel-server
   npm install
   ```

2. **Set up environment variables**:
   Create a `.env.local` file:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

3. **Run locally**:
   ```bash
   vercel dev
   ```

### Testing the API

You can test the API using curl:

```bash
curl -X POST https://your-vercel-app.vercel.app/api/openai-proxy \
  -H "Content-Type: application/json" \
  -d '{
    "persona": {
      "name": "Test",
      "relationship": "Assistant",
      "personality": ["Friendly"],
      "speechStyle": "Polite",
      "catchphrases": ["Hello"],
      "favoriteTopics": ["Test"]
    },
    "conversationHistory": [],
    "userMessage": "Hello, how are you?",
    "emotionContext": null
  }'
```

## 🔍 Troubleshooting

### Common Issues

1. **405 Method Not Allowed**
   - Ensure you're using POST method
   - Check that the URL is correct

2. **500 Server Error**
   - Verify `OPENAI_API_KEY` is set in Vercel dashboard
   - Check Vercel function logs for detailed error messages

3. **CORS Issues**
   - The API is configured to allow all origins (`*`)
   - If you need specific origins, modify the CORS headers in `openai-proxy.js`

4. **OpenAI API Errors**
   - Check your OpenAI API key is valid
   - Verify you have sufficient credits
   - Check OpenAI API status

### Debugging

1. **Check Vercel Function Logs**:
   - Go to your Vercel dashboard
   - Navigate to Functions tab
   - Click on the function to view logs

2. **Test API Key**:
   ```bash
   curl -H "Authorization: Bearer YOUR_API_KEY" \
        https://api.openai.com/v1/models
   ```

## 📝 Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | Your OpenAI API key | Yes |

## 🔒 Security

- The API key is stored securely in Vercel environment variables
- CORS is configured to allow cross-origin requests
- Input validation is performed on all requests
- Error messages are sanitized to prevent information leakage

## 📞 Support

If you encounter issues:

1. Check the Vercel function logs
2. Verify your OpenAI API key is valid
3. Test the API endpoint directly
4. Check the Swift app logs for detailed error messages

## 🚀 Deployment Checklist

- [ ] Deploy to Vercel
- [ ] Set `OPENAI_API_KEY` environment variable
- [ ] Test API endpoint
- [ ] Update Swift app configuration
- [ ] Test full integration 