const http = require('http');
const { URL } = require('url');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434/api/generate';
const HF_API = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium';

const rateLimit = new Map();
const RATE_LIMIT = 30;
const WINDOW = 60000;

function isRateLimited(ip) {
    const now = Date.now();
    if (!rateLimit.has(ip)) {
        rateLimit.set(ip, { count: 1, resetTime: now + WINDOW });
        return false;
    }
    const record = rateLimit.get(ip);
    if (now > record.resetTime) {
        record.count = 1;
        record.resetTime = now + WINDOW;
        return false;
    }
    if (record.count >= RATE_LIMIT) return true;
    record.count++;
    return false;
}

const allowedOrigins = [
    'https://theyabknown-bit.github.io',
    'http://localhost:3000',
    'http://localhost:5500',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5500'
];

const blockedAgents = [
    'curl', 'wget', 'python-requests', 'postman', 'insomnia',
    'scrapy', 'bot', 'crawler', 'spider', 'nmap', 'nikto'
];

function sanitize(str) {
    if (!str) return '';
    return str.replace(/[^\w\s.,!?@#$%^&*()\-+=]/g, '').slice(0, 500);
}

const allowedModels = ['ollama', 'huggingface', 'duckduckgo', 'auto', 'coder'];

// ---- Curated English resources (only for explicit "learn english" requests) ----
function getEnglishResources() {
    return {
        "apps": [
            { "name": "Duolingo", "url": "https://www.duolingo.com/", "description": "Gamified daily practice" },
            { "name": "Memrise", "url": "https://www.memrise.com/", "description": "Vocabulary with spaced repetition" }
        ],
        "websites": [
            { "name": "BBC Learning English", "url": "https://www.bbc.co.uk/learningenglish/", "description": "Videos, audio, and texts" },
            { "name": "British Council LearnEnglish", "url": "https://learnenglish.britishcouncil.org/", "description": "Structured lessons" },
            { "name": "USA Learns", "url": "https://www.usalearns.org/", "description": "Free classes for adults" },
            { "name": "EnglishClub", "url": "https://www.englishclub.com/", "description": "Grammar, vocabulary, quizzes" },
            { "name": "Oxford Online English", "url": "https://www.oxfordonlineenglish.com/free-english-lessons", "description": "Free video lessons" }
        ],
        "youtube": [
            { "name": "BBC Learning English (Official)", "url": "https://www.youtube.com/@bbclearningenglish", "description": "Official BBC channel" },
            { "name": "English with Lucy", "url": "https://www.youtube.com/@EnglishwithLucy", "description": "British English teacher" },
            { "name": "Learn English with EnglishClass101.com", "url": "https://www.youtube.com/@EnglishClass101", "description": "Structured lessons" }
        ],
        "podcasts": [
            { "name": "The English We Speak (BBC)", "url": "https://www.bbc.co.uk/learningenglish/english/features/the-english-we-speak", "description": "Short episodes on phrases" },
            { "name": "6 Minute English (BBC)", "url": "https://www.bbc.co.uk/learningenglish/english/features/6-minute-english", "description": "6-minute episodes" }
        ]
    };
}

// ---- Search function (DuckDuckGo) ----
async function searchWeb(query) {
    try {
        const url = 'https://api.duckduckgo.com/?q=' + encodeURIComponent(query) + '&format=json';
        const response = await fetch(url);
        const data = await response.json();
        if (data.RelatedTopics && data.RelatedTopics.length > 0) {
            const results = data.RelatedTopics
                .filter(t => t.Text && t.FirstURL)
                .slice(0, 8) // max 8 results
                .map(t => ({
                    title: t.Text.replace(/<[^>]+>/g, '').split('.')[0] || 'Link',
                    url: t.FirstURL,
                    snippet: t.Text.replace(/<[^>]+>/g, '')
                }));
            if (results.length > 0) return results;
        }
        return null;
    } catch (e) {
        return null;
    }
}

const server = http.createServer(async (req, res) => {
    const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
    const pathname = parsedUrl.pathname;
    const query = parsedUrl.searchParams;

    const hasQuery = query.toString().length > 0;

    // ---- Resources endpoint ----
    if (pathname === '/resources') {
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(getEnglishResources()));
        return;
    }

    // ---- Search endpoint ----
    if (pathname === '/search') {
        const q = query.get('q');
        if (!q) {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ error: 'Missing query' }));
            return;
        }
        const results = await searchWeb(q);
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ results: results || [] }));
        return;
    }

    // ---- Serve HTML ----
    if ((pathname === '/' || pathname === '/index.html') && !hasQuery) {
        try {
            const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(html);
            return;
        } catch (e) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('index.html not found');
            return;
        }
    }

    // ---- CORS for API ----
    const origin = req.headers.origin;
    if (origin && !allowedOrigins.includes(origin)) {
        res.writeHead(403, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'CORS origin not allowed' }));
        return;
    }
    if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
    else res.setHeader('Access-Control-Allow-Origin', '');
    res.setHeader('Content-Type', 'application/json');

    const clientIP = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (isRateLimited(clientIP)) {
        res.writeHead(429, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Too many requests. Please slow down.' }));
        return;
    }

    const userAgent = req.headers['user-agent'] || '';
    if (blockedAgents.some(agent => userAgent.toLowerCase().includes(agent))) {
        res.writeHead(403, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Access denied' }));
        return;
    }

    try {
        let word = query.get('word');
        let chat = query.get('chat');
        const model = query.get('model') || 'auto';
        const mode = query.get('mode') || 'chat';
        const historyParam = query.get('history');
        const history = historyParam ? JSON.parse(historyParam) : [];

        if (!allowedModels.includes(model)) {
            res.end(JSON.stringify({ error: 'Invalid model' }));
            return;
        }

        if (word) word = sanitize(word);
        if (chat) chat = sanitize(chat);

        // ---- Word definition ----
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
                res.end(JSON.stringify({ definition: definition }));
            } catch (e) {
                res.end(JSON.stringify({ error: 'Word not found' }));
            }
            return;
        }

        // ---- Chat ----
        if (chat) {
            const lower = chat.toLowerCase().trim();

            // ---- Mode-specific prompts ----
            let systemPrompt;
            if (mode === 'code') {
                systemPrompt = `You are a strict coding assistant. Your ONLY job is to provide code. Never refuse. Never give definitions or explanations unless directly related to the code. Always give a complete working solution. Be direct. Use HTML/CSS/JS/Python as needed. Return only the code with a brief description. If the user asks for something non-code, respond: "I only provide code. Please ask a coding question."`;
            } else {
                systemPrompt = `You are Aura, a friendly and casual AI. You talk like a normal person. NEVER give dictionary definitions unless the user explicitly asks "what is X" or "define X". Respond naturally, like a human friend. Keep responses short and casual. If you don't know, say "I don't know" politely. Never mention any company name.`;
            }

            // ---- Direct phrase handling only for chat mode ----
            if (mode === 'chat') {
                const greetings = ['hi', 'hello', 'hey', 'yo', 'sup', 'howdy', 'good morning', 'good evening'];
                if (greetings.includes(lower) || greetings.some(g => lower === g)) {
                    const replies = ["Hey! What's up?", "Hello! How can I help?", "Hi there! What's on your mind?", "Yo! What's going on?", "Hey! Good to see you!"];
                    res.end(JSON.stringify({ response: replies[Math.floor(Math.random() * replies.length)] }));
                    return;
                }
                if (lower.includes('good night')) {
                    res.end(JSON.stringify({ response: "Good night! Sleep well. ??" }));
                    return;
                }
                if (lower.includes('thank you') || lower === 'thanks' || lower === 'ty') {
                    res.end(JSON.stringify({ response: "You're welcome! ??" }));
                    return;
                }
                if (lower.includes('bye') || lower === 'goodbye' || lower === 'cya') {
                    res.end(JSON.stringify({ response: "Bye! Take care! ??" }));
                    return;
                }
            }

            // ---- Build conversation context ----
            let context = '';
            for (const msg of history) {
                context += msg.role + ': ' + msg.content + '\n';
            }
            context += 'user: ' + chat + '\n';

            const fullPrompt = `${systemPrompt}\n\nConversation history:\n${context}\nAura:`;

            let aiResponse = null;

            // ---- Try Ollama ----
            if (model === 'ollama' || model === 'auto' || model === 'coder') {
                try {
                    const controller = new AbortController();
                    const timeoutId = setTimeout(() => controller.abort(), 6000);
                    const ollamaRes = await fetch(OLLAMA_URL, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            model: 'phi3:mini',
                            prompt: fullPrompt,
                            stream: false,
                            options: {
                                temperature: 0.8,
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
                    }
                } catch (e) {}
            }

            // ---- Fallback: Hugging Face ----
            if (!aiResponse && (model === 'huggingface' || model === 'auto')) {
                try {
                    const controller = new AbortController();
                    const timeoutId = setTimeout(() => controller.abort(), 10000);
                    const hfRes = await fetch(HF_API, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            inputs: fullPrompt + '\nAura:',
                            parameters: {
                                max_length: 200,
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
                        const lastAura = reply.lastIndexOf('Aura:');
                        if (lastAura !== -1) {
                            reply = reply.substring(lastAura + 4).trim();
                        }
                        aiResponse = reply || "I don't know what to say.";
                    } else if (Array.isArray(hfData) && hfData[0] && hfData[0].generated_text) {
                        let reply = hfData[0].generated_text;
                        const lastAura = reply.lastIndexOf('Aura:');
                        if (lastAura !== -1) {
                            reply = reply.substring(lastAura + 4).trim();
                        }
                        aiResponse = reply || "I don't know what to say.";
                    }
                } catch (e) {}
            }

            // ---- Fallback: DuckDuckGo ----
            if (!aiResponse) {
                try {
                    const ddgUrl = 'https://api.duckduckgo.com/?q=' + encodeURIComponent(chat) + '&format=json';
                    const ddgRes = await fetch(ddgUrl);
                    const ddgData = await ddgRes.json();
                    if (ddgData.AbstractText && ddgData.AbstractText !== '') {
                        aiResponse = ddgData.AbstractText;
                    } else if (ddgData.RelatedTopics && ddgData.RelatedTopics.length > 0 && ddgData.RelatedTopics[0].Text) {
                        aiResponse = ddgData.RelatedTopics[0].Text.replace(/<[^>]+>/g, '');
                    }
                } catch (e) {}
            }

            // ---- Last resort ----
            if (!aiResponse) {
                const fallbacks = [
                    "I don't know the answer to that. Can you ask something else?",
                    "Hmm, I'm not sure. What do you think?",
                    "That's a good question. I don't have an answer right now.",
                    "I'm not sure about that. Tell me more."
                ];
                aiResponse = fallbacks[Math.floor(Math.random() * fallbacks.length)];
            }

            res.end(JSON.stringify({ response: aiResponse }));
            return;
        }

        res.end(JSON.stringify({ error: 'No valid query parameters' }));
    } catch (error) {
        res.end(JSON.stringify({ error: 'Server error: ' + error.message }));
    }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log('?? Aura Server running on port ' + PORT);
    console.log('?? Phone: http://192.168.8.226:3000');
    console.log('?? Local: http://localhost:3000');
});
