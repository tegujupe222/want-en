# Gemini 2.5 Flash Lite Setup Guide

This guide explains how to set up Google's Gemini 2.5 Flash Lite for the Want-EN iOS app.

## Option 1: Direct API Integration (Recommended)

### 1. Get Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy the API key

### 2. Configure the App

1. Open the app
2. Go to Settings > AI Settings
3. Enter your Gemini API key in the "Gemini 2.5 Flash Lite" section
4. Tap "Test Connection" to verify the setup

### 3. Benefits of Direct Integration

- **Lower latency**: Direct API calls without proxy
- **Better security**: API key stored locally on device
- **Cost effective**: No additional server costs
- **Simpler setup**: No server deployment required

## Option 2: Vercel Server Proxy

### 1. Deploy Vercel Server

1. Navigate to the `vercel-server` directory
2. Install dependencies: `npm install`
3. Deploy to Vercel: `npm run deploy`

### 2. Set Environment Variables in Vercel

1. Go to your Vercel project dashboard
2. Navigate to Settings > Environment Variables
3. Add the following variable:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Your Google Gemini API key
   - **Environment**: Production, Preview, Development

### 3. Update iOS App Configuration

1. Open `AIConfigManager.swift`
2. Set `useVercelProxy` to `true`
3. Update `vercelBaseURL` with your Vercel deployment URL

## Troubleshooting

### Common Issues

1. **API Key Not Set**
   - Ensure the API key is properly entered in the app settings
   - Check for extra spaces or characters

2. **Connection Failed**
   - Verify internet connection
   - Check if Gemini API is available in your region
   - Ensure API key has proper permissions

3. **Rate Limiting**
   - Gemini API has rate limits
   - Consider implementing request throttling for high usage

### Error Messages

- `API key not set`: Enter your Gemini API key in settings
- `Connection failed`: Check internet connection and API key validity
- `Rate limit exceeded`: Wait before making additional requests

## Privacy and Security

- API keys are stored locally on the device
- No conversation data is sent to external servers (except Gemini API)
- All communication is encrypted using HTTPS

## Cost Information

- Gemini 2.5 Flash Lite pricing: [Google AI Pricing](https://ai.google.dev/pricing)
- First 15 requests per minute are free
- Additional requests are charged per token

## Support

For issues with Gemini API:
- [Google AI Documentation](https://ai.google.dev/docs)
- [Google AI Studio](https://makersuite.google.com/)

For app-specific issues:
- Check the app's settings and configuration
- Ensure all required permissions are granted
