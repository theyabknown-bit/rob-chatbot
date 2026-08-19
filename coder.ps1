# coder.ps1 — Works for any "make a website/game/app" request
Clear-Host
Write-Host "🧑‍💻 Coder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray
Write-Host "Tell me what you want to build. I'll give you code."
Write-Host "Commands: :quit, :clear"
Write-Host ""

$conversationMemory = @()

function Get-Ollama {
    param($prompt)
    try {
        $body = @{ model = "phi3:mini"; prompt = $prompt; stream = $false; options = @{ temperature = 0.4; max_tokens = 400 } } | ConvertTo-Json -Depth 3
        $r = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 15 -ErrorAction Stop
        if ($r.response) { return $r.response }
        return $null
    } catch { return $null }
}

function Get-DuckDuckGo {
    param($q)
    try {
        $url = "https://api.duckduckgo.com/?q=" + [uri]::EscapeDataString($q) + "&format=json"
        $r = Invoke-RestMethod -Uri $url -TimeoutSec 5 -ErrorAction Stop
        if ($r.AbstractText -and $r.AbstractText -ne "") { return $r.AbstractText }
        if ($r.RelatedTopics -and $r.RelatedTopics.Count -gt 0) {
            $t = $r.RelatedTopics[0].Text
            if ($t) { return ($t -replace '<[^>]+>', '') }
        }
        return $null
    } catch { return $null }
}

function Get-SSUM {
    param($userInput)
    $l = $userInput.ToLower()
    $m = 0.5; $a = 0.0; $s = 0.0
    if ($l -match "code|script|program|build|create|make|website|game|app|clicker") { $m = 0.8; $a = 0.3 }
    if ($l -match "html|css|javascript|python") { $m = 0.9; $a = 0.4 }
    if ($l -match "help|guide|explain") { $m = 0.6; $a = 0.2 }
    $m = [Math]::Round($m + (Get-Random -Min -0.02 -Max 0.02), 4)
    $a = [Math]::Round($a + (Get-Random -Min -0.02 -Max 0.02), 4)
    $s = [Math]::Round($s + (Get-Random -Min -0.01 -Max 0.01), 4)
    if ($m -gt 1) { $m = 1 } if ($m -lt 0) { $m = 0 }
    if ($a -gt 1) { $a = 1 } if ($a -lt -1) { $a = -1 }
    if ($s -gt 1) { $s = 1 } if ($s -lt 0) { $s = 0 }
    return @{ m = $m; a = $a; s = $s }
}

function Get-CoderReply {
    param($userInput)
    $r = $userInput.Trim()
    $l = $r.ToLower()
    if ($l -eq ':quit' -or $l -eq ':exit') { return "QUIT" }
    if ($l -eq ':clear') { Clear-Host; return "Screen cleared." }

    # ---- Any request that could be code-related ----
    if ($l -match "make|build|create|write|code|website|game|app|html|python|javascript|script|program|clicker") {
        $context = ""
        if ($conversationMemory.Count -gt 0) {
            $lastFew = $conversationMemory[-6..-1]
            $context = ($lastFew -join "`n") + "`n"
        }
        $systemPrompt = "You are a coding assistant. Provide the requested code. Be direct. No excuses.`nConversation:`n${context}User: $r`nAssistant (code):"
        $response = Get-Ollama -prompt $systemPrompt
        if ($response) {
            $conversationMemory += "User: $r"; $conversationMemory += "Coder: $response"; return $response
        }
        $ddg = Get-DuckDuckGo -q $r
        if ($ddg) {
            $conversationMemory += "User: $r"; $conversationMemory += "Coder: $ddg"; return $ddg
        }
        # Fallback – simple HTML template (no complex quotes)
        return @"
I couldn't connect to AI. But here's a basic HTML page you can use:

<!DOCTYPE html>
<html>
<head><title>My Page</title></head>
<body>
<h1>Hello</h1>
<p>This is a simple page.</p>
</body>
</html>

Tell me what you want (e.g., add a button, style with CSS) and I'll expand it.
"@
    }

    # ---- General conversation ----
    return "I'm here for coding. Tell me what to build (e.g., 'make a clicker game', 'create a website with a button')."
}

while ($true) {
    Write-Host "you> " -NoNewline
    $userInput = Read-Host
    if ($userInput -eq "") { continue }
    $reply = Get-CoderReply -userInput $userInput
    if ($reply -eq "QUIT") { Write-Host "Goodbye!" -ForegroundColor Cyan; break }
    $ssum = Get-SSUM -userInput $userInput
    Write-Host "Coder: $reply" -ForegroundColor Green
    Write-Host "  [m=$($ssum.m) a=$($ssum.a) s=$($ssum.s)]" -ForegroundColor Gray
    Write-Host ""
}
