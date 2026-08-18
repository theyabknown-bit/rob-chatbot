const http = require('http');
const url = require('url');
const fetch = require('node-fetch');

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434/api/generate';
const HF_API = 'https://api-inference.huggingface.co/models/facebook/blenderbot-400M-distill';

const server = http.createServer(async (req, res) => {
    const query = url.parse(req.url, true).query;
    const word = query.word;
    const chat = query.chat;
    const model = query.model || 'ollama';
    const history = query.history ? JSON.parse(query.history) : [];
    
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');
    
    // ---- Word definitions ----
    if (word) {
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
    
    // ---- Chat ----
    if (chat) {
        // Build conversation context from history
        let context = '';
        for (let i = 0; i < history.length; i++) {
            const msg = history[i];
            context += msg.role + ': ' + msg.content + '\n';
        }
        // Add the current user message
        context += 'user: ' + chat + '\n';
        
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

        let aiResponse = null;
        let aiSource = null;
        let modelUsed = model;

        // ---- 1. Ollama ----
        if (model === 'ollama' || model === 'auto') {
            try {
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 5000);
                const ollamaRes = await fetch(OLLAMA_URL, {
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
                    }),
                    signal: controller.signal
                });
                clearTimeout(timeoutId);
                const ollamaData = await ollamaRes.json();
                if (ollamaData && ollamaData.response) {
                    aiResponse = ollamaData.response.trim();
                    aiSource = 'ollama';
                }
            } catch(e) {}
        }

        // ---- 2. Hugging Face ----
        if (!aiResponse && (model === 'huggingface' || model === 'auto')) {
            try {
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 10000);
                const hfRes = await fetch(HF_API, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        inputs: systemPrompt + '\nROB:',
                        parameters: {
                            max_length: 150,
                            temperature: 0.7,
                            top_p: 0.9
                        }
                    }),
                    signal: controller.signal
                });
                clearTimeout(timeoutId);
                const hfData = await hfRes.json();
                if (hfData && hfData.generated_text) {
                    let reply = hfData.generated_text;
                    const lastROB = reply.lastIndexOf('ROB:');
                    if (lastROB !== -1) {
                        reply = reply.substring(lastROB + 4).trim();
                    }
                    aiResponse = reply || "I'm sorry, I couldn't generate a response right now.";
                    aiSource = 'huggingface';
                }
            } catch(e) {}
        }

        // ---- 3. DuckDuckGo ----
        if (!aiResponse && (model === 'duckduckgo' || model === 'auto')) {
            try {
                const ddgUrl = 'https://api.duckduckgo.com/?q=' + encodeURIComponent(chat) + '&format=json';
                const ddgRes = await fetch(ddgUrl);
                const ddgData = await ddgRes.json();
                if (ddgData.AbstractText && ddgData.AbstractText !== '') {
                    aiResponse = ddgData.AbstractText;
                    aiSource = 'duckduckgo';
                } else if (ddgData.RelatedTopics && ddgData.RelatedTopics.length > 0 && ddgData.RelatedTopics[0].Text) {
                    aiResponse = ddgData.RelatedTopics[0].Text.replace(/<[^>]+>/g, '');
                    aiSource = 'duckduckgo';
                }
            } catch(e) {}
        }

        if (aiResponse) {
            res.end(JSON.stringify({ response: aiResponse, source: aiSource, model: modelUsed }));
            return;
        }

        res.end(JSON.stringify({ error: 'All AI services failed' }));
    }
    
    res.end('{"error":"No query parameter"}');
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log('🤖 ROB Server running on port ' + PORT);
    console.log('📚 Search: /?word=love');
    console.log('💬 Chat: /?chat=Hello&model=ollama');
});
