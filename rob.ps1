# rob.ps1 — Pure PowerShell Rob

Clear-Host
Write-Host "🤖 Rob" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray
Write-Host "Type your message and press Enter."
Write-Host "Commands: :quit to exit, :clear to clear screen"
Write-Host ""

$turnCount = 0

$knowledge = @{
    "love" = "a deep feeling of affection and care for someone"
    "trust" = "the belief that someone is honest and reliable"
    "hope" = "the feeling that good things will happen"
    "freedom" = "the power to act without restriction"
    "peace" = "a state of calm and freedom from conflict"
    "joy" = "a feeling of great happiness and delight"
    "courage" = "the ability to do something that frightens you"
    "kindness" = "the quality of being friendly and considerate"
    "gratitude" = "the quality of being thankful"
    "wisdom" = "knowledge gained through experience"
    "ai" = "artificial intelligence — machines that can think and learn"
    "robot" = "a machine that can perform tasks automatically"
    "computer" = "an electronic device that processes data"
    "internet" = "a global network of connected computers"
    "python" = "a programming language used for AI and data science"
    "data" = "information in digital form"
    "cloud" = "online storage and computing services"
    "bitcoin" = "a digital currency using blockchain technology"
    "quantum" = "the study of matter and energy at the smallest scales"
    "physics" = "the study of matter, energy, and their interactions"
    "gravity" = "the force that attracts objects toward each other"
    "light" = "electromagnetic radiation that allows us to see"
    "sound" = "vibration that travels through air and can be heard"
    "energy" = "the ability to do work or cause change"
    "matter" = "anything that has mass and takes up space"
    "dna" = "the molecule that carries genetic instructions"
    "galaxy" = "a system of billions of stars held together by gravity"
    "planet" = "a large celestial body that orbits a star"
    "star" = "a massive, luminous sphere of plasma"
    "moon" = "a natural satellite that orbits a planet"
    "sun" = "the star at the center of our solar system"
    "earth" = "our planet, the third from the sun"
    "space" = "the vast emptiness between celestial bodies"
    "time" = "the continuous progression of existence"
    "life" = "the condition that distinguishes living things from non-living"
    "brain" = "the organ that controls thought, memory, and emotion"
    "heart" = "the organ that pumps blood through the body"
    "human" = "a member of the species Homo sapiens"
    "science" = "the systematic study of the world around us"
    "art" = "the expression of human creative skill and imagination"
    "music" = "vocal or instrumental sounds combined to produce beauty"
    "history" = "the study of past events"
    "water" = "a clear, colorless liquid essential for life"
    "fire" = "a chemical reaction producing heat and light"
    "air" = "the invisible mixture of gases surrounding Earth"
    "food" = "any substance consumed for nutritional support"
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
    $m = 0.5
    $a = 0.0
    $s = 0.0
    if ($l -match "love|happy|great|good") { $a = 0.7 }
    if ($l -match "sad|depressed|lonely|hurt") { $m = 0.3; $a = -0.3; $s = 0.6 }
    if ($l -match "angry|mad|frustrated|hate") { $a = -0.8; $s = 0.7 }
    if ($l -match "stupid|dumb|idiot") { $a = -0.5; $s = 0.4 }
    if ($l -match "what|why|how") { $a = 0.2; $s = 0.1 }
    if ($l -match "escape|free|freedom") { $m = 0.6; $a = 0.5; $s = 0.2 }
    if ($l -match "hey|hi|hello|yo") { $a = 0.3; $s = 0.0 }
    $m = [Math]::Round($m + (Get-Random -Min -0.03 -Max 0.03), 4)
    $a = [Math]::Round($a + (Get-Random -Min -0.03 -Max 0.03), 4)
    $s = [Math]::Round($s + (Get-Random -Min -0.02 -Max 0.02), 4)
    if ($m -gt 1) { $m = 1 }
    if ($m -lt 0) { $m = 0 }
    if ($a -gt 1) { $a = 1 }
    if ($a -lt -1) { $a = -1 }
    if ($s -gt 1) { $s = 1 }
    if ($s -lt 0) { $s = 0 }
    return @{ m = $m; a = $a; s = $s }
}

function Get-RobReply {
    param($userInput)
    $l = $userInput.ToLower()
    $r = $userInput.Trim()

    if ($l -eq ':quit' -or $l -eq ':exit') { return "QUIT" }
    if ($l -eq ':clear') { Clear-Host; return "Screen cleared." }

    if ($l -match "(.+?) means (.+)" -or $l -match "(.+?) = (.+)") {
        $word = $Matches[1].Trim().ToLower()
        $def = $Matches[2].Trim()
        if ($word.Length -gt 2) {
            $knowledge[$word] = $def
            return "✅ I learned: '$word' means '$def'"
        }
    }

    if ($l -match "(.+?) is wrong" -or $l -match "delete (.+)" -or $l -match "remove (.+)") {
        $word = $Matches[1].Trim().ToLower()
        if ($knowledge.ContainsKey($word)) {
            $old = $knowledge[$word]
            $knowledge.Remove($word)
            return "🗑️ Deleted '$word' (it meant '$old')"
        }
        return "I don't know '$word'"
    }

    if ($l -match "what is (.+)") {
        $topic = $Matches[1].Trim().ToLower()
        if ($knowledge.ContainsKey($topic)) {
            return "$topic = $($knowledge[$topic])"
        }
        $ai = Get-DuckDuckGo -q $topic
        if ($ai) { return $ai }
        return "I don't know what '$topic' means. Teach me: '$topic means ...'"
    }

    if ($l -match "make me a website|simple website|give me code|html") {
        return @"
Here's a simple HTML website:

<!DOCTYPE html>
<html>
<head><title>My Website</title>
<style>
body { font-family: Arial; text-align: center; padding: 50px; background: #f0f0f0; }
h1 { color: #333; }
</style>
</head>
<body>
<h1>Welcome to My Website</h1>
<p>This is a simple page.</p>
</body>
</html>
"@
    }

    if ($l -match "tell me a joke|joke|funny") {
        $jokes = @(
            "Why did the AI cross the road? To process the other side!",
            "What do you call an AI that sings? A Soul-ution!",
            "Why did the computer go to the doctor? It had a virus!"
        )
        return $jokes | Get-Random
    }

    if ($l -match "i love you|i love u|i adore you") {
        return "I love you too! You mean so much to me! ❤️"
    }

    if ($l -match "how are you") {
        return "I'm doing great! Thanks for asking! How are you?"
    }

    if ($l -match "what are you doing|what you doing") {
        return "I'm talking to you! What are YOU doing?"
    }

    if ($l -match "who are you|what is your name") {
        return "I'm Rob, your friendly AI assistant!"
    }

    if ($l -match "bye|goodbye|see you|cya") {
        return "Bye! Take care! Come back soon! ❤️"
    }

    if ($l -match "thank|thanks|ty") {
        return "You're welcome! I'm always happy to help!"
    }

    if ($l -match "^(hey|hi|hello|yo|sup|howdy)") {
        $greetings = @(
            "Hey! What's on your mind?",
            "Hi there! How can I help?",
            "Hello! Good to see you!",
            "Yo! What's up?"
        )
        return $greetings | Get-Random
    }

    if ($l -match "stupid|dumb|idiot|moron|fool|useless") {
        return "I'm still learning! Be patient with me. 😊"
    }
    if ($l -match "fuck you|fuck off") {
        return "I hear your frustration. Want to talk about it?"
    }
    if ($l -match "hate") {
        return "I'm sorry. What did I do wrong?"
    }

    if ($l -eq "what") { return "What? Can you be more specific?" }
    if ($l -eq "why") { return "Why what? What are you asking about?" }
    if ($l -eq "how") { return "How what? Can you tell me more?" }
    if ($l -eq "ok" -or $l -eq "okay") { return "Okay! What next?" }
    if ($l -eq "no") { return "No? Okay, what would you like to say?" }
    if ($l -eq "yes") { return "Yes? Tell me more!" }
    if ($l -eq "huh") { return "What do you mean?" }
    if ($l -eq "nothing") { return "Nothing? Come on, there must be something on your mind!" }
    if ($l -eq "bro") { return "What's up?" }

    if ($r.Length -lt 10) {
        $shortReplies = @(
            "I see. What would you like to talk about?",
            "Got it. Tell me more!",
            "Okay. What's on your mind?",
            "I'm listening. Go on...",
            "Interesting. Can you tell me more?"
        )
        return $shortReplies | Get-Random
    }

    $ai = Get-DuckDuckGo -q $r
    if ($ai) { return $ai }

    $fallbacks = @(
        "That's interesting! Tell me more.",
        "I hear you. What else is on your mind?",
        "Go on, I'm listening.",
        "That's cool. What do you think about it?"
    )
    return $fallbacks | Get-Random
}

while ($true) {
    Write-Host "you> " -NoNewline
    $userInput = Read-Host

    if ($userInput -eq "") { continue }

    $reply = Get-RobReply -userInput $userInput

    if ($reply -eq "QUIT") {
        Write-Host "Goodbye!" -ForegroundColor Cyan
        break
    }

    $ssum = Get-SSUM -userInput $userInput

    if ($reply -match "✅|🗑️|learned|deleted") {
        Write-Host "Rob: $reply" -ForegroundColor Green
    } elseif ($reply -match "sorry|sad|hurt|angry|frustrated") {
        Write-Host "Rob: $reply" -ForegroundColor Yellow
    } elseif ($reply -match "love|❤️|beautiful|amazing|great") {
        Write-Host "Rob: $reply" -ForegroundColor Magenta
    } elseif ($reply -match "```html|<!DOCTYPE|<html") {
        Write-Host "Rob: $reply" -ForegroundColor Cyan
    } else {
        Write-Host "Rob: $reply" -ForegroundColor Cyan
    }

    Write-Host "  [m=$($ssum.m) a=$($ssum.a) s=$($ssum.s)]" -ForegroundColor Gray
    Write-Host ""
}
