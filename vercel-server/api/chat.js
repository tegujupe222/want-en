import OpenAI from 'openai';
import cors from 'cors';

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// CORS middleware
const corsMiddleware = cors({
  origin: '*', // In production, restrict this to your app's domain
  methods: ['POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type'],
});

export default async function handler(req, res) {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Promise((resolve) => {
      corsMiddleware(req, res, () => {
        res.status(200).end();
        resolve();
      });
    });
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Apply CORS
  await new Promise((resolve) => {
    corsMiddleware(req, res, resolve);
  });

  try {
    const { persona, conversationHistory, userMessage, emotionContext } = req.body;

    // Validate required fields
    if (!persona || !userMessage) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Build conversation context
    let systemPrompt = `You are ${persona.name}, a ${persona.relationship}. `;
    systemPrompt += `Your personality traits: ${persona.personality.join(', ')}. `;
    systemPrompt += `Your speech style: ${persona.speechStyle}. `;
    
    if (persona.catchphrases && persona.catchphrases.length > 0) {
      systemPrompt += `You often use phrases like: ${persona.catchphrases.join(', ')}. `;
    }
    
    if (persona.favoriteTopics && persona.favoriteTopics.length > 0) {
      systemPrompt += `You enjoy talking about: ${persona.favoriteTopics.join(', ')}. `;
    }

    // Add emotion context if provided
    if (emotionContext) {
      systemPrompt += `Current emotional context: ${emotionContext}. `;
    }

    systemPrompt += `\n\nPlease respond naturally and conversationally, staying true to your character. Keep responses concise but engaging.`;

    // Build conversation messages
    const messages = [
      { role: 'system', content: systemPrompt }
    ];

    // Add conversation history
    for (const message of conversationHistory) {
      if (message.isUser) {
        messages.push({ role: 'user', content: message.content });
      } else {
        messages.push({ role: 'assistant', content: message.content });
      }
    }

    // Add current user message
    messages.push({ role: 'user', content: userMessage });

    // Call OpenAI API
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Using GPT-4o-mini for better performance and cost
      messages: messages,
      max_tokens: 500,
      temperature: 0.7,
      presence_penalty: 0.1,
      frequency_penalty: 0.1,
    });

    const response = completion.choices[0]?.message?.content;

    if (!response) {
      throw new Error('No response from OpenAI');
    }

    // Return the response
    res.status(200).json({
      response: response,
      error: null
    });

  } catch (error) {
    console.error('OpenAI API Error:', error);
    
    // Handle specific OpenAI errors
    if (error.status === 401) {
      return res.status(401).json({ error: 'Invalid API key' });
    } else if (error.status === 429) {
      return res.status(429).json({ error: 'Rate limit exceeded' });
    } else if (error.status === 500) {
      return res.status(500).json({ error: 'OpenAI server error' });
    }

    res.status(500).json({
      response: null,
      error: error.message || 'Internal server error'
    });
  }
} 