const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// The rest of your server.js (Ollama, DuckDuckGo, etc.) goes here...
// I'll keep the minimal static server for this example – you can merge with your existing server.

const server = http.createServer((req, res) => {
    const parsed = url.parse(req.url, true);
    let filePath = '.' + parsed.pathname;
    if (filePath === './') filePath = './index.html';

    const ext = path.extname(filePath);
    const contentType = {
        '.html': 'text/html',
        '.js': 'application/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.ico': 'image/x-icon'
    }[ext] || 'text/plain';

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end('404 Not Found');
            return;
        }
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log('🚀 Server running on port ' + PORT);
    console.log('📄 Main page: http://localhost:3000');
    console.log('🤖 Aura page: http://localhost:3000/aura.html');
});
