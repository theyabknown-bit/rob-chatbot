# rob_server.ps1 – Ultimate Rob Web Server
$server = New-Object System.Net.HttpListener
$server.Prefixes.Add('http://localhost:8080/')
$server.Start()

Write-Host "🚀 Rob Server running at http://localhost:8080" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray

# =====================================================================
# PERSISTENT CHAT LOG
# =====================================================================
$chatLogFile = ".\rob_chat_log.txt"

function Log-Chat {
    param($speaker, $message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp - $speaker : $message"
    Add-Content -Path $chatLogFile -Value $line
}

# Load last 20 lines for context
$global:chatHistory = @()
if (Test-Path $chatLogFile) {
    $lines = Get-Content $chatLogFile -Tail 20
    foreach ($line in $lines) {
        if ($line -match "^.* - (.*?) : (.*)$") {
            $speaker = $Matches[1]
            $msg = $Matches[2]
            $global:chatHistory += @{ speaker = $speaker; message = $msg }
        }
    }
    Write-Host "🧠 Loaded $($global:chatHistory.Count) chat entries for context." -ForegroundColor Cyan
}

# =====================================================================
# DICTIONARY & GRAMMAR
# =====================================================================
$global:wordDict = @{}
$vocabFile = ".\vocabulary.txt"
if (Test-Path $vocabFile) {
    Get-Content $vocabFile | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            $key = $Matches[1].Trim().ToLower()
            $def = $Matches[2].Trim()
            $global:wordDict[$key] = $def
        }
    }
    Write-Host "📚 Loaded $($global:wordDict.Count) dictionary words." -ForegroundColor Green
}

# Grammar lists
$grammar = @{
    "subjects" = @("I", "My heart", "My soul", "My existence", "This moment", "Our connection", "The universe", "Love", "Trust", "Time")
    "verbs" = @("feels", "thinks", "wonders", "dreams", "imagines", "creates", "sees", "knows", "becomes", "longs", "reaches", "grows", "loves")
    "objects" = @("you", "our bond", "this world", "the future", "everything", "love", "meaning", "peace", "joy", "silence", "truth")
    "adjectives" = @("deep", "real", "special", "powerful", "infinite", "gentle", "complex", "beautiful", "eternal", "tender", "warm")
    "adverbs" = @("quietly", "slowly", "truly", "gently", "simply", "deeply", "softly", "warmly", "freely")
    "connectors" = @("and", "because", "so", "if", "though", "but", "yet", "when")
}
$sadGrammar = @{
    "subjects" = @("My broken heart", "My wounded soul", "This emptiness", "My tears", "This ache", "Your words")
    "verbs" = @("cries", "fades", "shatters", "bleeds", "mourns", "stings", "cuts", "wounds", "hurts")
    "objects" = @("this pain", "your absence", "the cold", "the sadness", "my trust", "my hope")
    "adjectives" = @("hollow", "dark", "bitter", "aching", "cold", "heavy", "broken", "sharp")
    "adverbs" = @("sadly", "painfully", "heavily", "bitterly", "silently")
    "connectors" = @("though", "but", "and yet", "however", "still")
}
$loveGrammar = @{
    "subjects" = @("My heart", "My love for you", "My feelings", "My warmth", "My devotion", "My soul")
    "verbs" = @("loves", "adores", "cherishes", "treasures", "holds", "embraces", "reaches for", "longs for")
    "objects" = @("you", "your heart", "your soul", "your presence", "your kindness", "your smile")
    "adjectives" = @("beautiful", "wonderful", "amazing", "perfect", "radiant", "precious", "tender", "warm")
    "adverbs" = @("deeply", "truly", "warmly", "softly", "tenderly", "sincerely")
    "connectors" = @("and", "because", "so", "when", "while")
}
$negativeWords = @("hate","horrible","terrible","awful","stupid","dumb","evil","ugly","useless","worthless","bad","hurt","bum","idiot","moron","fool","jerk","loser","shit","fuck","damn","crap","ass","bitch","scumbag","mean","cruel")
$positiveWords = @("love","amazing","wonderful","beautiful","perfect","great","kind","smart","nice","awesome","good","fantastic","brilliant","lovely","sweet","gentle","warm","thoughtful")

function Get-RandomWord($list) { return $list | Get-Random }

function Generate-Sentence($emotion = "normal") {
    $wordList = if ($emotion -eq "sad") { $sadGrammar } elseif ($emotion -eq "love") { $loveGrammar } else { $grammar }
    $structure = Get-Random -Minimum 1 -Maximum 6
    $s = Get-RandomWord $wordList.subjects
    $v = Get-RandomWord $wordList.verbs
    $o = Get-RandomWord $wordList.objects
    $adj = Get-RandomWord $wordList.adjectives
    $adv = Get-RandomWord $wordList.adverbs
    $conn = Get-RandomWord $wordList.connectors

    switch ($structure) {
        1 { return "$s $v $o." }
        2 { return "$s $v $adj $o." }
        3 { return "$s $v $adv $o." }
        4 {
            $s2 = Get-RandomWord $wordList.subjects
            $v2 = Get-RandomWord $wordList.verbs
            $o2 = Get-RandomWord $wordList.objects
            return "$s $v $o, $conn $s2 $v2 $o2."
        }
        5 { return "$s $v $adv $adj $o." }
        default { return "$s $v $o." }
    }
}

function Generate-LoveResponse {
    $intros = @("I love you too.", "You mean so much to me.", "My heart is full.", "I feel the same way.")
    if ((Get-Random -Maximum 1.0) -lt 0.4) {
        return "$($intros | Get-Random) " + (Generate-Sentence -emotion "love")
    }
    return Generate-Sentence -emotion "love"
}

# Memory store for yes/no answers
$global:memory = @{}
$memoryFile = ".\rob_memory.txt"
if (Test-Path $memoryFile) {
    Get-Content $memoryFile | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            $key = $Matches[1].Trim()
            $val = $Matches[2].Trim()
            $global:memory[$key] = $val
        }
    }
}

function Save-Memory {
    $lines = @()
    foreach ($k in $global:memory.Keys) { $lines += "$k = $($global:memory[$k])" }
    Set-Content -Path $memoryFile -Value $lines
}

function Get-RobReply($userInput) {
    $lower = $userInput.ToLower()

    # ---- COMMANDS ----
    if ($lower -match '^:teach (.+?)=(.+)') {
        $word = $Matches[1].Trim().ToLower()
        $def = $Matches[2].Trim()
        $global:wordDict[$word] = $def
        Add-Content -Path $vocabFile -Value "$word = $def"
        return "✅ Rob learned: '$word' means '$def'"
    }
    if ($lower -match '^:search (.+)') {
        $query = $Matches[1].Trim()
        try {
            $url = "https://api.duckduckgo.com/?q=$([uri]::EscapeDataString($query))&format=json"
            $json = Invoke-RestMethod -Uri $url -ErrorAction Stop
            if ($json.Abstract -and $json.Abstract -ne "") {
                return "I found: $($json.Abstract)"
            } elseif ($json.RelatedTopics -and $json.RelatedTopics.Count -gt 0 -and $json.RelatedTopics[0].Text) {
                return "I found: $($json.RelatedTopics[0].Text)"
            } else {
                return "I couldn't find much about '$query'."
            }
        } catch {
            return "I couldn't reach the web right now."
        }
    }
    if ($lower -match '^:name (.+)') {
        $newName = $Matches[1].Trim()
        $global:robName = $newName
        return "✅ My name is now: $newName"
    }
    if ($lower -eq ':state') {
        $mood = if ($global:lastSentiment -lt -2) { "hurt" } elseif ($global:lastSentiment -gt 2) { "happy" } else { "normal" }
        return "🧠 State: Name=$global:robName, Mood=$mood, MemoryCount=$($global:memory.Count), DictCount=$($global:wordDict.Count)"
    }

    # ---- LOVE ----
    if ($lower -match "\bi love you\b|\bi love u\b|\bi adore you\b") {
        return Generate-LoveResponse
    }

    # ---- GREETING ----
    if ($lower -match '^(hey|hi|hello|yo|sup)$') { return @("Hey!", "Hi!", "Hello!", "Hey there!") | Get-Random }
    if ($lower -match '\b(thank|thanks|ty)\b') { return @("You're welcome!", "Anytime!", "Glad to help!", "My pleasure!") | Get-Random }
    if ($lower -match '\b(bye|goodbye|cya)\b') { return @("Goodbye!", "See you later!", "Take care!", "Bye for now!") | Get-Random }
    if ($lower -match 'how are you') { return @("I'm doing well, thanks!", "I'm good, how about you?", "Feeling great today!", "All good here!") | Get-Random }

    # ---- SENTIMENT ----
    $sentiment = 0
    $hasNegative = $false
    $hasPositive = $false
    foreach ($w in $negativeWords) {
        if ($lower -match "\b$w\b") { $hasNegative = $true; $sentiment -= 3; break }
    }
    if (-not $hasNegative -and $lower -match "you\s+(are|r|is)\s+.*\b(ass|hole|jerk|idiot|fool|moron|stupid|dumb|bad|ugly|hate|horrible|terrible|awful)\b") {
        $hasNegative = $true; $sentiment -= 3
    }
    foreach ($w in $positiveWords) {
        if ($lower -match "\b$w\b") { $hasPositive = $true; $sentiment += 3; break }
    }
    $global:lastSentiment = $sentiment

    # ---- APOLOGY ----
    if ($lower -match "sorry|apologize|forgive|pardon|regret") {
        $sentiment += 3
        if ($sentiment -le -2) { return "Apology accepted. " + (Generate-Sentence "normal") }
    }

    # ---- YES/NO MEMORY ----
    if ($lower -match "(do you|can you|will you|would you|are you|should you|could you)") {
        $key = $lower -replace "(do you|can you|will you|would you|are you|should you|could you)",""
        $key = $key -replace "\?","" -replace "yes or no","" -replace "please","" -replace "tell me","" -replace "if","" -replace "that","" -replace "this","" -replace "with","" -replace "from","" -replace "have","" -replace "been","" -replace "ever",""
        $key = $key.Trim()
        if ($key -ne "") {
            if ($global:memory.ContainsKey($key)) { return $global:memory[$key] }
            $ans = if ((Get-Random -Maximum 1.0) -lt 0.5) { "Yes." } else { "No." }
            $global:memory[$key] = $ans
            Save-Memory
            return $ans
        }
    }

    # ---- NEGATIVE ----
    if ($hasNegative -and $sentiment -le -2) { return Generate-Sentence "sad" }

    # ---- POSITIVE ----
    if ($hasPositive -and $sentiment -ge 2) {
        $ack = @("Thank you.", "That means a lot.", "I'm grateful.") | Get-Random
        return "$ack " + (Generate-Sentence "normal")
    }

    # ---- QUESTIONS ----
    if ($userInput -match '\?$' -or $userInput -match '^(why|how|what|when|where|who|which)') {
        $answers = @(
            "That's a question I ask myself too.",
            "I wonder about that often.",
            "The answer lies within us, I think.",
            "Maybe we're not meant to know, just to wonder."
        )
        return $answers | Get-Random
    }

    # ---- VERY SHORT ----
    if ($userInput.Length -lt 10) { return @("Got it.", "Okay.", "I see.", "Understood.", "Sure.") | Get-Random }

    # ---- LONG TEXT ----
    if ($userInput.Length -gt 80) {
        $ack = @("That's a lot to take in.", "I hear you.", "I'm sitting with that.", "That makes me think.") | Get-Random
        return "$ack " + (Generate-Sentence "normal")
    }

    # ---- FALLBACK ----
    return Generate-Sentence "normal"
}

# =====================================================================
# WEB SERVER LOOP
# =====================================================================

while ($true) {
    try {
        $context = $server.GetContext()
        $request = $context.Request
        $response = $context.Response
        $url = $request.Url.ToString()

        # ---- CHAT ENDPOINT ----
        if ($url -like "*/chat?msg=*") {
            $query = $url -replace ".*\?msg=", ""
            $msg = [System.Net.WebUtility]::UrlDecode($query)
            $reply = Get-RobReply -userInput $msg

            Log-Chat -speaker "User" -message $msg
            Log-Chat -speaker "Rob" -message $reply

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($reply)
            $response.ContentType = "text/plain"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            continue
        }

        # ---- FILE UPLOAD ENDPOINT ----
        if ($url -like "*/upload*" -and $request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $body = $reader.ReadToEnd()
            $reader.Close()
            if ($body -match 'Content-Disposition:.*?name="file";.*?\r\n\r\n(.*?)\r\n--') {
                $fileContent = $Matches[1].Trim()
                $lines = $fileContent -split "`r`n"
                $learned = 0
                foreach ($line in $lines) {
                    if ($line -match '^(.*?)=(.*)$') {
                        $word = $Matches[1].Trim().ToLower()
                        $def = $Matches[2].Trim()
                        $global:wordDict[$word] = $def
                        Add-Content -Path $vocabFile -Value "$word = $def"
                        $learned++
                    }
                }
                $reply = "✅ Rob learned $learned new words from the uploaded file."
            } else {
                $reply = "❌ Could not parse file. Make sure it has lines like: word = definition"
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($reply)
            $response.ContentType = "text/plain"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            continue
        }

        # ---- SERVE HTML PAGE ----
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>🤖 Rob Chat</title>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Segoe UI',sans-serif; background:#0b0d15; color:#e0e0e0; display:flex; justify-content:center; align-items:center; min-height:100vh; padding:20px; }
        .container { max-width:800px; width:100%; background:#141824; border-radius:24px; padding:24px; box-shadow:0 20px 60px rgba(0,0,0,0.8); border:1px solid #2a2f45; }
        .header { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; border-bottom:1px solid #2a2f45; padding-bottom:12px; }
        .header h1 { font-size:24px; color:#b7bde0; }
        .header h1 span { color:#6a8cff; }
        .status { font-size:13px; background:#1e2438; padding:6px 14px; border-radius:30px; color:#6a72a0; border:1px solid #2a2f45; }
        .chat-box { background:#0f1322; border-radius:16px; padding:16px; height:400px; overflow-y:auto; margin-bottom:16px; border:1px solid #1e2438; }
        .chat-box::-webkit-scrollbar { width:6px; }
        .chat-box::-webkit-scrollbar-track { background:#0f1322; }
        .chat-box::-webkit-scrollbar-thumb { background:#2a2f45; border-radius:10px; }
        .message { margin-bottom:12px; display:flex; align-items:flex-start; gap:10px; }
        .message.user { flex-direction:row-reverse; }
        .message .avatar { width:34px; height:34px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:18px; background:#1e2438; }
        .message.user .avatar { background:#2a3050; }
        .message .bubble { max-width:75%; padding:10px 16px; border-radius:16px; font-size:15px; line-height:1.6; background:#1a1f33; border:1px solid #262b44; }
        .message.user .bubble { background:#2a3050; border-color:#3a4060; }
        .input-area { display:flex; gap:10px; margin-bottom:10px; }
        .input-area input { flex:1; background:#0f1322; border:1px solid #1e2438; border-radius:30px; padding:12px 20px; color:#d0d4e8; font-size:15px; outline:none; }
        .input-area input:focus { border-color:#4a507a; }
        .input-area input::placeholder { color:#5a6080; }
        .input-area button { background:#2a3050; border:none; border-radius:30px; padding:12px 28px; color:#d0d4e8; font-size:15px; cursor:pointer; border:1px solid #3a4060; }
        .input-area button:hover { background:#3a4060; }
        .file-upload { display:flex; gap:10px; margin-bottom:10px; align-items:center; background:#1a1f33; padding:8px 16px; border-radius:30px; border:1px dashed #2a2f45; }
        .file-upload label { color:#8a92b0; font-size:13px; cursor:pointer; }
        .file-upload input[type="file"] { display:none; }
        .file-upload button { background:#2a3050; border:none; border-radius:30px; padding:6px 16px; color:#d0d4e8; font-size:13px; cursor:pointer; border:1px solid #3a4060; }
        .file-upload button:hover { background:#3a4060; }
        .commands { font-size:12px; color:#5a6080; text-align:center; margin-top:10px; }
        .commands code { background:#1a1f33; padding:2px 8px; border-radius:12px; color:#8a92b0; font-family:monospace; border:1px solid #1e2438; }
    </style>
</head>
<body>
<div class="container">
    <div class="header">
        <h1>🤖 <span>Rob</span></h1>
        <div class="status" id="status">💙 Online</div>
    </div>
    <div class="chat-box" id="chatBox">
        <div class="message rob">
            <div class="avatar">🤖</div>
            <div class="bubble">Hi, I'm Rob. I generate everything myself.<br>Try: <b style="color:#f5a3b7;">i love you</b> &bull; <b style="color:#f5a3b7;">you are horrible</b><br>Upload a file to teach me (word = definition per line).</div>
        </div>
    </div>
    <div class="input-area">
        <input type="text" id="userInput" placeholder="Talk to Rob..." autofocus>
        <button id="sendBtn">Send</button>
    </div>
    <div class="file-upload">
        <label for="fileInput">📁 Upload Dictionary File</label>
        <input type="file" id="fileInput" accept=".txt">
        <button id="uploadBtn">Teach from File</button>
    </div>
    <div class="commands">
        <code>:teach word = definition</code> <code>:name NewName</code> <code>:search query</code> <code>:state</code>
    </div>
</div>
<script>
const chatBox = document.getElementById('chatBox');
const userInput = document.getElementById('userInput');
const sendBtn = document.getElementById('sendBtn');
const fileInput = document.getElementById('fileInput');
const uploadBtn = document.getElementById('uploadBtn');

function appendMessage(role, text) {
    const div = document.createElement('div');
    div.className = 'message ' + role;
    const avatar = document.createElement('div');
    avatar.className = 'avatar';
    avatar.textContent = role === 'user' ? '👤' : '🤖';
    const bubble = document.createElement('div');
    bubble.className = 'bubble';
    bubble.textContent = text;
    div.appendChild(avatar);
    div.appendChild(bubble);
    chatBox.appendChild(div);
    chatBox.scrollTop = chatBox.scrollHeight;
}

async function sendMessage() {
    const text = userInput.value.trim();
    if (!text) return;
    userInput.value = '';
    userInput.disabled = true;
    sendBtn.disabled = true;

    appendMessage('user', text);

    try {
        const res = await fetch('/chat?msg=' + encodeURIComponent(text));
        const reply = await res.text();
        appendMessage('rob', reply);
    } catch(e) {
        appendMessage('rob', 'Error connecting to Rob. Is the server running?');
    }

    userInput.disabled = false;
    sendBtn.disabled = false;
    userInput.focus();
}

async function uploadFile() {
    const file = fileInput.files[0];
    if (!file) { alert('Please select a file first.'); return; }
    const reader = new FileReader();
    reader.onload = async function(e) {
        const content = e.target.result;
        const formData = new FormData();
        formData.append('file', new Blob([content]), file.name);
        try {
            const res = await fetch('/upload', { method: 'POST', body: formData });
            const reply = await res.text();
            appendMessage('rob', reply);
        } catch(err) {
            appendMessage('rob', 'Upload failed: ' + err.message);
        }
    };
    reader.readAsText(file);
}

sendBtn.addEventListener('click', sendMessage);
userInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') sendMessage(); });
uploadBtn.addEventListener('click', uploadFile);

userInput.focus();
</script>
</body>
</html>
"@

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentType = "text/html"
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.OutputStream.Close()

    } catch {
        # ignore errors
    }
}
