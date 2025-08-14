# Gemini 2.5 Flash Lite Setup Guide

This guide explains how to set up Google's Gemini 2.5 Flash Lite for the Want-EN iOS app using Vercel proxy.

## Vercel Server Proxy Setup (Required)

### 1. Deploy Vercel Server

1. Navigate to the project root directory
2. Install dependencies: `npm install`
3. Deploy to Vercel: `vercel --prod`

### 2. Set Environment Variables in Vercel

1. Go to your Vercel project dashboard
2. Navigate to Settings > Environment Variables
3. Add the following variable:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Your Google Gemini API key
   - **Environment**: Production, Preview, Development

### 3. Get Your Vercel Deployment URL

After deployment, you'll get a URL like: `https://your-project.vercel.app`

### 4. Configure iOS App

1. Open the app
2. Go to Settings > AI Settings
3. Enter your Vercel deployment URL in the "Vercel Base URL" field
4. Tap "Test Connection" to verify the setup

## Benefits of Vercel Proxy

- **Enhanced Security**: API key managed server-side, not exposed in app
- **Centralized Management**: Single point for API key updates
- **Rate Limiting**: Server-side rate limiting and monitoring
- **CORS Support**: Proper cross-origin request handling
- **Error Handling**: Centralized error handling and logging

## Troubleshooting

### Common Issues

1. **Vercel URL Not Set**
   - Ensure the Vercel deployment URL is properly entered in the app settings
   - Check for extra spaces or characters

2. **Connection Failed**
   - Verify internet connection
   - Check if Vercel deployment is active
   - Ensure environment variables are set correctly in Vercel

3. **API Key Issues**
   - Verify `GEMINI_API_KEY` is set in Vercel environment variables
   - Check if the API key has proper permissions
   - Ensure the API key is valid and not expired

### Error Messages

- `Vercel URL not set`: Enter your Vercel deployment URL in settings
- `Connection failed`: Check internet connection and Vercel deployment status
- `Unauthorized`: Check API key configuration in Vercel
- `Rate limit exceeded`: Wait before making additional requests

## Privacy and Security

- API keys are stored securely on Vercel servers
- No API keys are stored in the iOS app
- All communication is encrypted using HTTPS
- Conversation data is only sent to Gemini API through Vercel proxy

## Cost Information

- Gemini 2.5 Flash Lite pricing: [Google AI Pricing](https://ai.google.dev/pricing)
- First 15 requests per minute are free
- Additional requests are charged per token
- Vercel hosting costs: Free tier available

## Support

For issues with Gemini API:
- [Google AI Documentation](https://ai.google.dev/docs)
- [Google AI Studio](https://makersuite.google.com/)

For Vercel deployment issues:
- [Vercel Documentation](https://vercel.com/docs)
- Check Vercel dashboard for deployment status

For app-specific issues:
- Check the app's settings and configuration
- Ensure Vercel URL is correctly configured
- Verify environment variables are set in Vercel
