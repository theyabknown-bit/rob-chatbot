const http = require('http');
const url = require('url');
const fetch = require('node-fetch');

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434/api/generate';
let conversationHistory = [];
const MAX_HISTORY = 20;

const server = http.createServer(async (req, res) => {
    const query = url.parse(req.url, true).query;
    const word = query.word;
    const chat = query.chat;
    
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');
    
    if (word) {
        // Use DuckDuckGo for word definitions (no local dependency)
        try {
            const ddgUrl = 'https://api.duckduckgo.com/?q=' + encodeURIComponent(word) + '&format=json';
            const ddgRes = await fetch(ddgUrl);
            const ddgData = await ddgRes.json();
            let definition = null;
            if (ddgData.AbstractText && ddgData.AbstractText !== '') {
                definition = ddgData.AbstractText;
            } else if (ddgData.RelatedTopics && ddgData.RelatedTopics.length > 0 && ddgData.RelatedTopics[0].Text) {
                definition = ddgData.RelatedTopics[0].Text.replace(/<[^>]+>/g, '');
            }
            res.end(JSON.stringify({ definition: definition, source: 'duckduckgo' }));
            return;
        } catch(e) {
            res.end(JSON.stringify({ error: 'Word not found' }));
            return;
        }
    }
    
    if (chat) {
        try {
            const userMessage = chat;
            conversationHistory.push({ role: 'user', content: userMessage });
            if (conversationHistory.length > MAX_HISTORY) {
                conversationHistory = conversationHistory.slice(-MAX_HISTORY);
            }
            
            let context = '';
            for (let i = 0; i < conversationHistory.length; i++) {
                const msg = conversationHistory[i];
                context += msg.role + ': ' + msg.content + '\n';
            }
            
            const systemPrompt = `You are ROB, an AI assistant.

RULES:
1. If asked "who made you?" say "I don't know who made me. Do you know?"
2. If told "I made you" say "Oh, you made me? That's amazing! Tell me more."
3. Answer questions directly. Don't change the subject.
4. Keep responses short, natural, and varied.
5. Use conversation history to remember context.

CONVERSATION HISTORY:
${context}

ROB'S RESPONSE (only your reply):`;

            const response = await fetch(OLLAMA_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'phi3:mini',
                    prompt: systemPrompt,
                    stream: false,
                    options: {
                        temperature: 0.6,
                        max_tokens: 300,
                        top_p: 0.9
                    }
                })
            });
            
            const data = await response.json();
            
            if (data && data.response) {
                const reply = data.response.trim();
                conversationHistory.push({ role: 'assistant', content: reply });
                if (conversationHistory.length > MAX_HISTORY) {
                    conversationHistory = conversationHistory.slice(-MAX_HISTORY);
                }
                res.end(JSON.stringify({ response: reply, source: 'ollama' }));
                return;
            }
            
            res.end(JSON.stringify({ error: 'Ollama not responding' }));
        } catch(e) {
            res.end(JSON.stringify({ error: 'Server error: ' + e.message }));
        }
        return;
    }
    
    res.end('{"error":"No query parameter"}');
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log('🤖 ROB Server running on port ' + PORT);
    console.log('📚 Search: /?word=love');
    console.log('💬 Chat: /?chat=Hello');
});
