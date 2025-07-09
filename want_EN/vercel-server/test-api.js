#!/usr/bin/env node

/**
 * Test script for want_EN Vercel API
 * Usage: node test-api.js [vercel-url]
 */

const https = require('https');

// Default test URL (replace with your actual Vercel URL)
const DEFAULT_URL = 'https://your-vercel-app.vercel.app/api/openai-proxy';

// Test data
const testData = {
  persona: {
    name: "Test Assistant",
    relationship: "Friend",
    personality: ["Friendly", "Helpful", "Knowledgeable"],
    speechStyle: "Casual and warm",
    catchphrases: ["Hello there!", "How can I help you today?"],
    favoriteTopics: ["Technology", "Science", "Learning"]
  },
  conversationHistory: [
    {
      content: "Hi!",
      isFromUser: true,
      timestamp: new Date().toISOString()
    }
  ],
  userMessage: "Hello! How are you today?",
  emotionContext: "Happy and excited"
};

function makeRequest(url, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);
    
    const options = {
      hostname: new URL(url).hostname,
      port: 443,
      path: new URL(url).pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsedData = JSON.parse(responseData);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: parsedData
          });
        } catch (error) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

async function testAPI(url) {
  console.log('🧪 Testing want_EN Vercel API...');
  console.log(`📍 URL: ${url}`);
  console.log('📤 Sending test request...\n');

  try {
    const response = await makeRequest(url, testData);
    
    console.log('📊 Response Details:');
    console.log(`   Status Code: ${response.statusCode}`);
    console.log(`   Content-Type: ${response.headers['content-type']}`);
    console.log(`   CORS Headers: ${response.headers['access-control-allow-origin'] || 'Not set'}`);
    
    console.log('\n📄 Response Body:');
    if (response.statusCode === 200) {
      console.log('✅ Success!');
      if (response.data.response) {
        console.log(`   AI Response: "${response.data.response}"`);
      }
      if (response.data.error) {
        console.log(`   Error: ${response.data.error}`);
      }
    } else {
      console.log('❌ Error Response:');
      console.log(JSON.stringify(response.data, null, 2));
    }
    
    // Additional checks
    console.log('\n🔍 Additional Checks:');
    console.log(`   ✅ POST method accepted: ${response.statusCode !== 405}`);
    console.log(`   ✅ CORS configured: ${response.headers['access-control-allow-origin'] ? 'Yes' : 'No'}`);
    console.log(`   ✅ JSON response: ${response.headers['content-type']?.includes('application/json') ? 'Yes' : 'No'}`);
    
  } catch (error) {
    console.error('❌ Request failed:', error.message);
    
    if (error.code === 'ENOTFOUND') {
      console.log('\n💡 Troubleshooting:');
      console.log('   - Check if the URL is correct');
      console.log('   - Verify the Vercel deployment is live');
      console.log('   - Ensure the API endpoint path is correct');
    } else if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Troubleshooting:');
      console.log('   - The server might be down');
      console.log('   - Check Vercel deployment status');
    }
  }
}

// Main execution
const url = process.argv[2] || DEFAULT_URL;

if (url === DEFAULT_URL) {
  console.log('⚠️  Using default URL. Please provide your actual Vercel URL as an argument:');
  console.log('   node test-api.js https://your-vercel-app.vercel.app/api/openai-proxy\n');
}

testAPI(url); 