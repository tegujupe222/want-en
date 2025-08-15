import { GoogleGenerativeAI } from '@google/generative-ai';

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { prompt, persona, conversationHistory } = req.body;

    // Validate required fields
    if (!prompt) {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    // Get API key from environment variable
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error('GEMINI_API_KEY environment variable is not set');
      return res.status(500).json({ error: 'API key not configured' });
    }

    // Initialize Gemini API
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-lite' });

    // Build conversation context
    let conversationContext = '';
    
    if (persona) {
      conversationContext += `Persona Information:\n`;
      conversationContext += `Name: ${persona.name}\n`;
      conversationContext += `Relationship: ${persona.relationship}\n`;
      conversationContext += `Personality: ${persona.personality}\n`;
      conversationContext += `Speech Style: ${persona.speechStyle}\n`;
      conversationContext += `\nPlease respond as this persona would, maintaining their personality and speech style.\n\n`;
    }

    // Add conversation history if provided
    if (conversationHistory && conversationHistory.length > 0) {
      conversationContext += 'Previous conversation:\n';
      conversationHistory.forEach((message, index) => {
        if (index < conversationHistory.length - 10) return; // Keep last 10 messages for context
        conversationContext += `${message.isUser ? 'User' : 'Assistant'}: ${message.content}\n`;
      });
      conversationContext += '\n';
    }

    // Create the full prompt
    const fullPrompt = conversationContext + `Current message: ${prompt}`;

    console.log('🤖 Sending request to Gemini 2.0 Flash Lite');
    console.log('📝 Prompt length:', fullPrompt.length, 'characters');

    // Generate response
    const result = await model.generateContent(fullPrompt);
    const response = await result.response;
    const text = response.text();

    console.log('✅ Response generated successfully');
    console.log('📝 Response length:', text.length, 'characters');

    // Return the response
    res.status(200).json({
      success: true,
      response: text,
      model: 'gemini-2.0-flash-lite'
    });

  } catch (error) {
    console.error('❌ Error in Gemini proxy:', error);
    
    // Handle specific Gemini API errors
    if (error.message.includes('API_KEY_INVALID')) {
      return res.status(401).json({ error: 'Invalid API key' });
    }
    
    if (error.message.includes('QUOTA_EXCEEDED')) {
      return res.status(429).json({ error: 'API quota exceeded' });
    }
    
    if (error.message.includes('SAFETY')) {
      return res.status(400).json({ error: 'Content blocked by safety filters' });
    }

    // Generic error response
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
}
