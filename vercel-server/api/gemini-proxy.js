import { GoogleGenerativeAI } from '@google/generative-ai';

export default async function handler(req, res) {
  // CORS設定
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { prompt, persona, conversationHistory } = req.body;

    if (!prompt) {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    // 環境変数からAPIキーを取得
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'Gemini API key not configured' });
    }

    // Gemini APIクライアントを初期化
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-exp' });

    // ペルソナと会話履歴を含むプロンプトを構築
    let fullPrompt = '';
    
    if (persona) {
      fullPrompt += `Persona: ${persona.name}\n`;
      fullPrompt += `Relationship: ${persona.relationship}\n`;
      fullPrompt += `Personality: ${persona.personality}\n`;
      fullPrompt += `Communication Style: ${persona.communicationStyle}\n`;
      fullPrompt += `Interests: ${persona.interests}\n`;
      fullPrompt += `Background: ${persona.background}\n\n`;
    }

    if (conversationHistory && conversationHistory.length > 0) {
      fullPrompt += 'Previous conversation:\n';
      conversationHistory.forEach(msg => {
        const role = msg.isFromUser ? 'User' : 'Assistant';
        fullPrompt += `${role}: ${msg.content}\n`;
      });
      fullPrompt += '\n';
    }

    fullPrompt += `User: ${prompt}\nAssistant:`;

    // Gemini APIにリクエストを送信
    const result = await model.generateContent(fullPrompt);
    const response = await result.response;
    const text = response.text();

    res.status(200).json({
      response: text,
      model: 'gemini-2.0-flash-exp',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Gemini API Error:', error);
    res.status(500).json({
      error: 'Failed to generate response',
      details: error.message
    });
  }
}
