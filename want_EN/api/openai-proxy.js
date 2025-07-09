// OpenAI Proxy API for want_EN app
// Handles requests from Swift client to OpenAI API

export default async function handler(req, res) {
  // Enable CORS for all origins
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  
  // Only allow POST requests
  if (req.method !== 'POST') {
    console.error('❌ Method not allowed:', req.method);
    return res.status(405).json({ 
      error: 'Method not allowed. Only POST requests are supported.',
      method: req.method 
    });
  }
  
  try {
    console.log('🚀 OpenAI Proxy API called');
    console.log('📝 Request body:', JSON.stringify(req.body, null, 2));
    
    // Validate request body
    if (!req.body || !req.body.userMessage) {
      console.error('❌ Invalid request: missing userMessage');
      return res.status(400).json({ 
        error: 'Invalid request: userMessage is required' 
      });
    }
    
    // Get OpenAI API key from environment
    const openaiApiKey = process.env.OPENAI_API_KEY;
    if (!openaiApiKey) {
      console.error('❌ OPENAI_API_KEY not set in environment');
      return res.status(500).json({ 
        error: 'OpenAI API key not configured on server' 
      });
    }
    
    console.log('🔑 OpenAI API key found (length: ' + openaiApiKey.length + ')');
    
    // Extract data from request
    const { persona, conversationHistory, userMessage, emotionContext } = req.body;
    
    // Build conversation history for OpenAI
    const messages = [];
    
    // Add system message with persona context
    const systemPrompt = buildSystemPrompt(persona, emotionContext);
    messages.push({
      role: 'system',
      content: systemPrompt
    });
    
    // Add conversation history
    if (conversationHistory && conversationHistory.length > 0) {
      for (const message of conversationHistory) {
        messages.push({
          role: message.isFromUser ? 'user' : 'assistant',
          content: message.content
        });
      }
    }
    
    // Add current user message
    messages.push({
      role: 'user',
      content: userMessage
    });
    
    console.log('📨 Sending request to OpenAI API');
    console.log('💬 Messages count:', messages.length);
    
    // Call OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey}`
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: messages,
        max_tokens: 1000,
        temperature: 0.7
      })
    });
    
    console.log('📡 OpenAI API response status:', openaiResponse.status);
    
    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text();
      console.error('❌ OpenAI API error:', errorText);
      return res.status(openaiResponse.status).json({
        error: `OpenAI API error: ${openaiResponse.status} - ${errorText}`
      });
    }
    
    const openaiData = await openaiResponse.json();
    console.log('✅ OpenAI API response received');
    
    // Extract the response text
    const responseText = openaiData.choices?.[0]?.message?.content;
    if (!responseText) {
      console.error('❌ No response text in OpenAI response');
      return res.status(500).json({
        error: 'No response text received from OpenAI'
      });
    }
    
    console.log('💬 Response text:', responseText.substring(0, 100) + '...');
    
    // Return success response
    res.status(200).json({
      response: responseText,
      error: null
    });
    
  } catch (error) {
    console.error('❌ Server error:', error);
    res.status(500).json({
      error: `Server error: ${error.message}`,
      response: null
    });
  }
}

// Helper function to build system prompt
function buildSystemPrompt(persona, emotionContext) {
  let prompt = `You are ${persona.name}, a ${persona.relationship}. `;
  
  if (persona.personality && persona.personality.length > 0) {
    prompt += `Your personality traits include: ${persona.personality.join(', ')}. `;
  }
  
  if (persona.speechStyle) {
    prompt += `Your speech style is: ${persona.speechStyle}. `;
  }
  
  if (persona.catchphrases && persona.catchphrases.length > 0) {
    prompt += `You often use these phrases: ${persona.catchphrases.join(', ')}. `;
  }
  
  if (persona.favoriteTopics && persona.favoriteTopics.length > 0) {
    prompt += `You love talking about: ${persona.favoriteTopics.join(', ')}. `;
  }
  
  if (emotionContext) {
    prompt += `Current emotional context: ${emotionContext}. `;
  }
  
  prompt += `Please respond naturally as ${persona.name}, maintaining your unique personality and relationship with the user. Keep responses conversational and engaging.`;
  
  return prompt;
} 