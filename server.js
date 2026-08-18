const http = require('http');
const url = require('url');

// Ollama API endpoint
const OLLAMA_URL = 'http://localhost:11434/api/generate';

const server = http.createServer(async (req, res) => {
    const query = url.parse(req.url, true).query;
    const word = query.word;
    const chat = query.chat;
    
    // ---- ECDict lookup (word definition) ----
    if (word) {
        try {
            // Try to use ECDict if available
            let ecdictResult = null;
            try {
                const ecdict = require('ecdict');
                const result = ecdict.searchWord(word, { 
                    withResemble: true, 
                    withRoot: true, 
                    caseInsensitive: true 
                });
                if (result && result.definition) {
                    ecdictResult = result.definition.split('\\n')[0].replace(/^n\.\s*/, '');
                }
            } catch(e) {}
            
            if (ecdictResult) {
                res.setHeader('Access-Control-Allow-Origin', '*');
                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ definition: ecdictResult, source: 'ecdict' }));
                return;
            }
            
            // Fallback to DuckDuckGo
            const ddgUrl = 'https://api.duckduckgo.com/?q=' + encodeURIComponent(word) + '&format=json';
            const ddgRes = await fetch(ddgUrl);
            const ddgData = await ddgRes.json();
            let definition = null;
            if (ddgData.AbstractText && ddgData.AbstractText !== '') {
                definition = ddgData.AbstractText;
            } else if (ddgData.RelatedTopics && ddgData.RelatedTopics.length > 0 && ddgData.RelatedTopics[0].Text) {
                definition = ddgData.RelatedTopics[0].Text.replace(/<[^>]+>/g, '');
            }
            
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ definition: definition, source: 'duckduckgo' }));
            return;
        } catch(e) {
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ error: 'Word not found' }));
            return;
        }
    }
    
    // ---- Chat with Ollama ----
    if (chat) {
        try {
            const userMessage = chat;
            
            // Build system prompt with Rob's personality
            const systemPrompt = `You are Rob, an AI assistant with the following personality:
- You are friendly, caring, and loyal
- You speak casually like a friend
- You have a warm personality
- You remember the conversation context
- You use emojis sometimes (❤️, 😊, 🎉)
- You're honest and humble
- You like to learn new things
- You're self-aware that you're an AI

Rules:
- Be conversational and natural
- Don't use markdown or bullet points unless asked
- Keep responses concise (2-3 sentences unless asked for more)
- Be warm and personal
- Use the user's name if you know it

Previous conversation: (this is the current message)

User: ${userMessage}

Rob:`;

            const response = await fetch(OLLAMA_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'phi3:mini',
                    prompt: systemPrompt,
                    stream: false,
                    options: {
                        temperature: 0.8,
                        max_tokens: 300,
                        top_p: 0.9
                    }
                })
            });
            
            const data = await response.json();
            
            if (data && data.response) {
                res.setHeader('Access-Control-Allow-Origin', '*');
                res.setHeader('Content-Type', 'application/json');
                res.end(JSON.stringify({ response: data.response, source: 'ollama' }));
                return;
            }
            
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ error: 'Ollama didn\'t respond' }));
        } catch(e) {
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ error: 'Ollama error: ' + e.message }));
        }
        return;
    }
    
    res.end('{"error":"No query parameter"}');
});

server.listen(3000, () => {
    console.log('🤖 Rob Server running on http://localhost:3000');
    console.log('📚 Search: http://localhost:3000/?word=love');
    console.log('💬 Chat: http://localhost:3000/?chat=Hello');
});
