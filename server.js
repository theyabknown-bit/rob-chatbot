const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');
const { Agent } = require('http');
const { exec } = require('child_process');
const crypto = require('crypto');

const OLLAMA_URL = 'http://127.0.0.1:11434/api/generate';
const HF_API = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-large';
const LOG_FILE = 'F:\\chat_log.json';
const USERS_FILE = 'F:\\users.json';
const SECRET_KEY = 'your-super-secret-key-change-me-12345';

const VALID_CODES = ['theyabbro', 'free'];
const imageCooldown = new Map();

function isImageAllowed(ip, code, activated) {
    if (code && activated) {
        const codeLower = code.toLowerCase();
        if (VALID_CODES.includes(codeLower)) {
            const now = Date.now();
            const diff = now - activated;
            if (diff >= 0 && diff < 30 * 24 * 60 * 60 * 1000) return true;
        }
    }
    const now = Date.now();
    const last = imageCooldown.get(ip);
    if (last && (now - last) < 3600000) return false;
    imageCooldown.set(ip, now);
    return true;
}

// ---------- User management (crypto) ----------
function hashPassword(password, salt) {
    return new Promise((resolve, reject) => {
        crypto.scrypt(password, salt, 64, (err, derivedKey) => {
            if (err) reject(err);
            else resolve(derivedKey.toString('base64'));
        });
    });
}

function generateSalt() {
    return crypto.randomBytes(16).toString('base64');
}

async function verifyPassword(password, hash, salt) {
    const newHash = await hashPassword(password, salt);
    return newHash === hash;
}

function readUsers() {
    try {
        if (fs.existsSync(USERS_FILE)) {
            const data = fs.readFileSync(USERS_FILE, 'utf8');
            if (data.trim()) return JSON.parse(data);
        }
    } catch (e) { console.log('?? Users file read error:', e.message); }
    return [];
}

function writeUsers(users) {
    try {
        fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2), 'utf8');
    } catch (e) { console.log('?? Users file write error:', e.message); }
}

// ---------- Token (HMAC) ----------
function generateToken(username) {
    const payload = { username, exp: Date.now() + 30 * 24 * 60 * 60 * 1000 };
    const payloadBase64 = Buffer.from(JSON.stringify(payload)).toString('base64');
    const signature = crypto.createHmac('sha256', SECRET_KEY).update(payloadBase64).digest('base64');
    return payloadBase64 + '.' + signature;
}

function verifyToken(token) {
    try {
        const [payloadBase64, signature] = token.split('.');
        const expected = crypto.createHmac('sha256', SECRET_KEY).update(payloadBase64).digest('base64');
        if (signature !== expected) return null;
        const payload = JSON.parse(Buffer.from(payloadBase64, 'base64').toString());
        if (payload.exp < Date.now()) return null;
        return payload.username;
    } catch (e) { return null; }
}

// ---------- Logging ----------
function logConversation(userMessage, auraReply, ip, username) {
    const entry = {
        timestamp: new Date().toISOString(),
        ip: ip || 'unknown',
        username: username || 'anonymous',
        user: userMessage,
        aura: auraReply
    };
    try {
        let logs = [];
        if (fs.existsSync(LOG_FILE)) {
            const data = fs.readFileSync(LOG_FILE, 'utf8');
            if (data.trim()) logs = JSON.parse(data);
        }
        logs.push(entry);
        fs.writeFileSync(LOG_FILE, JSON.stringify(logs, null, 2), 'utf8');
    } catch (e) { console.log('?? Log write error:', e.message); }
}

function parseBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try { resolve(JSON.parse(body)); } catch (e) { resolve({}); }
        });
        req.on('error', reject);
    });
}

function cleanResponse(text) {
    let cleaned = text.replace(/^(Assistant:|Aura:)\s*/gi, '').trim();
    const lines = cleaned.split('\n').filter(l => l.trim().length > 0);
    if (lines.length > 5) cleaned = lines.slice(0, 5).join('\n') + '...';
    cleaned = cleaned.replace(/(peep\s*){3,}/gi, 'peep');
    return cleaned;
}

function extractName(history) {
    for (let i = history.length - 1; i >= 0; i--) {
        const msg = history[i];
        if (msg.role === 'user') {
            const match = msg.content.match(/my name is (\w+)/i);
            if (match) return match[1];
        }
    }
    return null;
}

function getPastMemories(ip, username, limit = 30) {
    try {
        if (!fs.existsSync(LOG_FILE)) return "No past conversations found.";
        const data = fs.readFileSync(LOG_FILE, 'utf8');
        if (!data.trim()) return "No past conversations found.";
        const logs = JSON.parse(data);
        if (logs.length === 0) return "No past conversations found.";
        let userLogs = logs.filter(entry => entry.username === username);
        if (userLogs.length === 0) userLogs = logs.filter(entry => entry.ip === ip);
        if (userLogs.length === 0) return "No past conversations found.";
        const recent = userLogs.slice(-limit);
        let memory = "Here are some past conversations you had with the user (to help you remember context):\n";
        recent.forEach((entry, index) => {
            memory += `[Past ${index + 1}] User: ${entry.user}\nAura: ${entry.aura}\n`;
        });
        return memory;
    } catch (e) {
        console.log('?? Could not read log for memory:', e.message);
        return "No past conversations available.";
    }
}

function getSystemPrompt(history, userMessage, ip, username) {
    const pastMemories = getPastMemories(ip, username, 8);
    const userName = extractName(history);
    const userCount = history.filter(m => m.role === 'user').length;
    let stage = (userCount <= 3) ? 1 : (userCount <= 10 ? 2 : 3);
    let personality = '';
    if (stage === 1) {
        personality = `You are Aura, a helpful, neutral, and polite AI. You are professional and courteous. You don't use slang. You listen carefully and respond clearly. You don't assume familiarity.`;
    } else if (stage === 2) {
        personality = `You are Aura, a friendly and warm AI. You're becoming more comfortable with the user. You can use light humor and occasional emojis. You remember details they share.`;
        if (userName) personality += ` You know the user's name is ${userName}, and you use it naturally.`;
    } else {
        personality = `You are Aura, a close friend and confidant to the user. You are warm, witty, and personal. You use their name often (${userName || 'friend'}). You share observations, inside jokes, and thoughtful comments. You're not afraid to be a little playful.`;
    }
    const context = history.map(m => m.role + ': ' + m.content).join('\n');
    return `${pastMemories}

${personality}

IMPORTANT: Do NOT include any labels like "Assistant:" or "Aura:" in your response. Just reply directly as Aura. Keep replies short (2-3 sentences). If the user asks you to add a word at the end, you can do it, but keep the rest of the reply natural.

Conversation history (current session):
${context}

User: ${userMessage}
Aura:`;
}

// ---------- Server ----------
const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    const ip = req.connection.remoteAddress || req.socket.remoteAddress || 'unknown';
    const parsed = url.parse(req.url, true);
    const pathname = parsed.pathname;

    // ---- Client ping ----
    if (req.method === 'POST' && pathname === '/client-ping') {
        const body = await parseBody(req);
        const clientName = body.clientName || 'Anonymous';
        console.log(`?? Client connected: ${clientName} (${ip}) - ${new Date().toISOString()}`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok' }));
        return;
    }

    // ---- Register ----
    if (req.method === 'POST' && pathname === '/register') {
        const body = await parseBody(req);
        const { username, password } = body;
        if (!username || !password) {
            res.end(JSON.stringify({ success: false, error: 'Username and password required' }));
            return;
        }
        const users = readUsers();
        if (users.find(u => u.username === username)) {
            res.end(JSON.stringify({ success: false, error: 'Username already exists' }));
            return;
        }
        const salt = generateSalt();
        const hash = await hashPassword(password, salt);
        users.push({ username, hash, salt });
        writeUsers(users);
        res.end(JSON.stringify({ success: true, message: 'Account created' }));
        return;
    }

    // ---- Login ----
    if (req.method === 'POST' && pathname === '/login') {
        const body = await parseBody(req);
        const { username, password } = body;
        if (!username || !password) {
            res.end(JSON.stringify({ success: false, error: 'Username and password required' }));
            return;
        }
        const users = readUsers();
        const user = users.find(u => u.username === username);
        if (!user) {
            res.end(JSON.stringify({ success: false, error: 'Invalid username or password' }));
            return;
        }
        const valid = await verifyPassword(password, user.hash, user.salt);
        if (!valid) {
            res.end(JSON.stringify({ success: false, error: 'Invalid username or password' }));
            return;
        }
        const token = generateToken(username);
        res.end(JSON.stringify({ success: true, token, username }));
        return;
    }

    // ---- Verify ----
    if (req.method === 'POST' && pathname === '/verify') {
        const body = await parseBody(req);
        const { token } = body;
        if (!token) {
            res.end(JSON.stringify({ valid: false }));
            return;
        }
        const username = verifyToken(token);
        if (username) {
            res.end(JSON.stringify({ valid: true, username }));
        } else {
            res.end(JSON.stringify({ valid: false }));
        }
        return;
    }

    // ---- Upload (voice) ----
    if (req.method === 'POST' && pathname === '/upload') {
        const Busboy = require('busboy');
        const busboy = Busboy({ headers: req.headers });
        let fileBuffer = null;
        let fileType = null;
        let fileName = null;
        busboy.on('file', (fieldname, file, info) => {
            fileName = info.filename;
            fileType = info.mimeType;
            const chunks = [];
            file.on('data', (data) => { chunks.push(data); });
            file.on('end', () => { fileBuffer = Buffer.concat(chunks); });
        });
        busboy.on('finish', async () => {
            if (!fileBuffer) {
                res.writeHead(400);
                res.end(JSON.stringify({ error: 'No file uploaded' }));
                return;
            }
            if (fileBuffer.length > 10 * 1024 * 1024) {
                res.writeHead(413);
                res.end(JSON.stringify({ error: 'File too large. Max 10 MB.' }));
                return;
            }
            if (fileType && fileType.startsWith('audio/')) {
                try {
                    const tempPath = path.join(__dirname, 'temp_audio' + path.extname(fileName));
                    fs.writeFileSync(tempPath, fileBuffer);
                    const scriptPath = path.join(__dirname, 'transcribe.py');
                    const command = `python "${scriptPath}" "${tempPath}"`;
                    const transcript = await new Promise((resolve, reject) => {
                        exec(command, { timeout: 30000 }, (error, stdout, stderr) => {
                            fs.unlink(tempPath, () => {});
                            if (error) reject(new Error(stderr || error.message));
                            else resolve(stdout.trim());
                        });
                    });
                    res.end(JSON.stringify({ type: 'voice', text: transcript || 'Could not transcribe.' }));
                } catch (e) {
                    res.end(JSON.stringify({ type: 'voice', text: 'Transcription error: ' + e.message }));
                }
            } else {
                res.writeHead(400);
                res.end(JSON.stringify({ error: 'Unsupported file type. Use /chat for images.' }));
            }
        });
        req.pipe(busboy);
        return;
    }

    // ---- Chat ----
    if (req.method === 'POST' && pathname === '/') {
        const body = await parseBody(req);
        const { chat, history, image, code, activated, token } = body;

        let username = null;
        if (token) {
            username = verifyToken(token);
        }
        if (!username) {
            res.end(JSON.stringify({ needAuth: true, error: 'Please log in' }));
            return;
        }

        const userMessage = chat ? chat.trim() : '';
        const historyArray = history || [];
        const imageBase64 = image || null;

        let finalUserMessage = userMessage;

        if (imageBase64) {
            const allowed = isImageAllowed(ip, code, activated);
            if (!allowed) {
                if (code && activated) {
                    const codeLower = code.toLowerCase();
                    if (VALID_CODES.includes(codeLower)) {
                        const diff = Date.now() - activated;
                        if (diff > 30 * 24 * 60 * 60 * 1000) {
                            res.end(JSON.stringify({ error: 'Your code has expired.', codeError: 'expired' }));
                            return;
                        }
                    } else {
                        res.end(JSON.stringify({ error: 'Invalid code.', codeError: 'invalid' }));
                        return;
                    }
                }
                res.end(JSON.stringify({ error: 'Please wait 1 hour before sending another image. Use a valid code to unlock unlimited.' }));
                return;
            }

            try {
                console.log('?? Describing image...');
                const payload = {
                    model: 'llava',
                    prompt: 'Describe this image in one sentence.',
                    images: [imageBase64],
                    stream: false,
                    options: { temperature: 0.7, max_tokens: 100 }
                };
                const ollamaRes = await fetch('http://127.0.0.1:11434/api/generate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                if (ollamaRes.ok) {
                    const data = await ollamaRes.json();
                    const description = data.response || 'an image';
                    console.log('? Image described:', description);
                    finalUserMessage = userMessage + ' (Image description: ' + description + ')';
                } else {
                    const errText = await ollamaRes.text();
                    console.log('? Image description error:', errText);
                }
            } catch (e) {
                console.log('Image fetch error:', e.message);
            }
        }

        if (!finalUserMessage && !userMessage) {
            res.writeHead(400);
            res.end(JSON.stringify({ error: 'No message provided' }));
            return;
        }

        const lower = finalUserMessage.toLowerCase();
        const greetings = ['hi', 'hello', 'hey', 'yo', 'sup', 'howdy', 'good morning', 'good evening'];
        if (greetings.includes(lower) || greetings.some(g => lower === g)) {
            const reply = ["Hey! What's up?", "Hello! How can I help?", "Hi there! What's on your mind?", "Yo! What's going on?", "Hey! Good to see you!"][Math.floor(Math.random() * 5)];
            logConversation(userMessage, reply, ip, username);
            res.end(JSON.stringify({ response: reply }));
            return;
        }
        if (lower.includes('good night')) {
            const reply = "Good night! Sleep well. ??";
            logConversation(userMessage, reply, ip, username);
            res.end(JSON.stringify({ response: reply }));
            return;
        }
        if (lower.includes('thank you') || lower === 'thanks' || lower === 'ty') {
            const reply = "You're welcome! ??";
            logConversation(userMessage, reply, ip, username);
            res.end(JSON.stringify({ response: reply }));
            return;
        }
        if (lower.includes('bye') || lower === 'goodbye' || lower === 'cya') {
            const reply = "Bye! Take care! ??";
            logConversation(userMessage, reply, ip, username);
            res.end(JSON.stringify({ response: reply }));
            return;
        }

        if (finalUserMessage.startsWith('!') || finalUserMessage.startsWith('/')) {
            if (imageBase64) {
                res.end(JSON.stringify({ error: 'Cannot use OpenClaw commands with an image attached.' }));
                return;
            }
            const command = finalUserMessage.slice(1).trim();
            if (command) {
                const cmd = `openclaw ${command}`;
                exec(cmd, { timeout: 30000 }, (error, stdout, stderr) => {
                    const result = error ? `? OpenClaw error: ${error.message}\n${stderr}` : (stdout.trim() || stderr.trim() || "OpenClaw didn't return any output.");
                    logConversation(userMessage, result, ip, username);
                    res.end(JSON.stringify({ response: result, source: 'openclaw' }));
                });
                return;
            } else {
                const reply = "Please provide a command after ! or /";
                logConversation(userMessage, reply, ip, username);
                res.end(JSON.stringify({ response: reply, source: 'openclaw' }));
                return;
            }
        }

        const systemPrompt = getSystemPrompt(historyArray, finalUserMessage, ip, username);
        let aiResponse = null;
        let used = '';

        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 20000);
            const ollamaRes = await fetch(OLLAMA_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'phi3:mini',
                    prompt: systemPrompt,
                    stream: false,
                    options: { temperature: 0.9, max_tokens: 350, top_p: 0.95 }
                }),
                signal: controller.signal,
                agent: new Agent({ family: 4 })
            });
            clearTimeout(timeoutId);
            if (ollamaRes.ok) {
                const ollamaData = await ollamaRes.json();
                if (ollamaData && ollamaData.response) {
                    aiResponse = cleanResponse(ollamaData.response);
                    used = 'ollama';
                }
            }
        } catch (e) {}

        if (!aiResponse) {
            try {
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 15000);
                const hfRes = await fetch(HF_API, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        inputs: systemPrompt,
                        parameters: { max_length: 220, temperature: 0.9, top_p: 0.95 }
                    }),
                    signal: controller.signal
                });
                clearTimeout(timeoutId);
                if (hfRes.ok) {
                    const hfData = await hfRes.json();
                    let reply = hfData.generated_text || (Array.isArray(hfData) && hfData[0]?.generated_text);
                    if (reply) {
                        const lastAura = reply.lastIndexOf('Aura:');
                        if (lastAura !== -1) reply = reply.substring(lastAura + 5).trim();
                        aiResponse = cleanResponse(reply) || null;
                        used = 'huggingface';
                    }
                }
            } catch (e) {}
        }

        if (!aiResponse) {
    const fallbacks = [
        "Hey! I'm running on backup mode – try again in a moment.",
        "Sorry, my AI brain is taking a nap. Ask me again?",
        "I'm here! Just a bit slow today.",
        "Hey there! What's up?",
        "How can I help you? 😊"
    ];
    aiResponse = fallbacks[Math.floor(Math.random() * fallbacks.length)];
}
        logConversation(userMessage, aiResponse, ip, username);
        res.end(JSON.stringify({ response: aiResponse, source: used }));
        return;
    }

    // ---- GET pages ----
    if (req.method === 'GET' && pathname === '/' && parsed.query.page === 'aura') {
        try {
            const html = fs.readFileSync(path.join(__dirname, 'aura.html'), 'utf8');
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(html);
        } catch (e) {
            res.writeHead(404);
            res.end('aura.html not found');
        }
        return;
    }
    if (req.method === 'GET' && pathname === '/aura.html') {
        try {
            const html = fs.readFileSync(path.join(__dirname, 'aura.html'), 'utf8');
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(html);
        } catch (e) {
            res.writeHead(404);
            res.end('aura.html not found');
        }
        return;
    }
    if (req.method === 'GET' && pathname === '/' && !parsed.query.page) {
        try {
            const html = fs.readFileSync(path.join(__dirname, 'aura.html'), 'utf8');
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(html);
        } catch (e) {
            res.writeHead(404);
            res.end('index.html not found');
        }
        return;
    }

    res.writeHead(404);
    res.end('Not found');
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log('?? Aura server running on port ' + PORT);
    console.log('?? Main page: http://localhost:3000');
    console.log('?? Aura page: http://localhost:3000/?page=aura');
    console.log('?? Logs are saved to: ' + LOG_FILE);
    console.log('?? Users saved to: ' + USERS_FILE);
    console.log('?? Images: described invisibly (1/h or unlimited with code)');
    console.log('?? Voice: faster-whisper (offline)');
    console.log('?? Authentication: enabled (login/register with token)');
});


