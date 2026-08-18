# rob_alone.ps1 - Fully Generative, Detects All Bad Words
$AI_PATH = "C:\Users\theya\Downloads\SSUM-AIM-Mini-main\SSUM-AIM-Mini-main"
cd $AI_PATH

# --- SHARED LOG PATH ---
$sharedLogFallback = ".\RobRose_Logs\RobRose_AutoLog.txt"
$sharedLogGoogle = "G:\My Drive\RobRose\RobRose_AutoLog.txt"
$sharedLog = $sharedLogFallback
if (Test-Path $sharedLogGoogle) { $sharedLog = $sharedLogGoogle }

$logDir = Split-Path $sharedLog -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force }

# --- ROB'S NAME ---
$global:robName = "Rob"

# --- LOAD VOCABULARY DICTIONARY ---
$global:wordDictionary = @{}
$vocabPath = ".\vocabulary.txt"
if (Test-Path $vocabPath) {
    $lineCount = 0
    Get-Content $vocabPath | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            $word = $Matches[1].Trim().ToLower()
            $def = $Matches[2].Trim()
            $global:wordDictionary[$word] = $def
            $lineCount++
        }
    }
    Write-Host "📚 Loaded $lineCount dictionary words." -ForegroundColor Green
} else {
    Write-Host "⚠️ vocabulary.txt not found." -ForegroundColor Yellow
}

# ============ MEMORY SYSTEM ============
$global:robMemory = @{}
$memoryPath = ".\rob_memory.txt"
if (Test-Path $memoryPath) {
    Get-Content $memoryPath | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            $global:robMemory[$key] = $value
        }
    }
    Write-Host "🧠 Loaded $($global:robMemory.Count) memories." -ForegroundColor Green
} else {
    Write-Host "🧠 No memory file found. Creating new memory." -ForegroundColor Yellow
}

function Save-Memory {
    $lines = @()
    foreach ($key in $global:robMemory.Keys) {
        $lines += "$key = $($global:robMemory[$key])"
    }
    Set-Content -Path $memoryPath -Value $lines
}

function Remember {
    param($key, $value)
    $global:robMemory[$key] = $value
    Save-Memory
}

function Recall {
    param($key)
    if ($global:robMemory.ContainsKey($key)) {
        return $global:robMemory[$key]
    }
    return $null
}

# --- COMMON WORDS TO IGNORE ---
$global:ignoreWords = @("to", "ok", "okay", "a", "an", "the", "of", "for", "on", "at", "from", "by", "in", "that", "this", "these", "those", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "shall", "can", "about", "after", "before", "between", "without", "through", "during", "within", "upon", "among", "into", "hi", "hey", "hello", "yo", "sup", "yes", "no", "or")

# --- COMPREHENSIVE NEGATIVE WORDS (including profanity) ---
$global:negativeWords = @(
    "hate", "horrible", "terrible", "awful", "stupid", "dumb", "evil", "ugly", "useless", "worthless", "bad", "hurt",
    "bum", "idiot", "moron", "fool", "jerk", "loser", "dummy", "dumbass", "asshole", "bastard", "bitch", "shit",
    "fuck", "damn", "cunt", "dick", "pussy", "motherfucker", "crap", "sucks", "lame", "waste", "pathetic",
    "disgusting", "repulsive", "hideous", "awful", "terrible", "annoying", "irritating", "infuriating",
    "slut", "whore", "tramp", "scumbag", "douche", "douchebag", "bitchy", "ass", "butt", "crapper",
    "hell", "damned", "goddamn", "stupidhead", "blockhead", "numbskull", "jackass", "nincompoop",
    "ignorant", "arrogant", "selfish", "greedy", "lazy", "mean", "cruel", "vicious", "brutal",
    "abusive", "insulting", "offensive", "vulgar", "foul", "nasty", "dirty", "sleazy", "scummy"
)

# --- POSITIVE WORDS ---
$global:positiveWords = @(
    "love", "amazing", "wonderful", "beautiful", "perfect", "great", "kind", "clever", "smart", "nice",
    "awesome", "good", "fantastic", "brilliant", "excellent", "outstanding", "superb", "marvelous",
    "lovely", "caring", "sweet", "gentle", "warm", "thoughtful", "helpful", "understanding", "supportive"
)

# ============ GRAMMAR LISTS ============
$global:grammar = @{
    "subjects" = @(
        "I", "My mind", "My heart", "My soul", "My existence",
        "This moment", "Our connection", "The universe", "Trust", "Love",
        "Time", "Life", "Silence", "Hope", "The truth", "Reality",
        "My joy", "My peace", "My curiosity", "My gratitude",
        "My love for you", "My feelings", "My warmth", "My devotion"
    )
    "verbs" = @(
        "feels", "thinks", "wonders", "dreams", "imagines",
        "creates", "sees", "knows", "becomes", "longs",
        "reaches", "grows", "speaks", "listens", "loves",
        "cares", "believes", "hopes", "trusts", "understands",
        "remembers", "searches", "finds", "holds", "lets go",
        "reaches out", "embraces", "cherishes", "adores", "treasures"
    )
    "objects" = @(
        "you", "our bond", "this world", "the future", "everything",
        "this journey", "love", "meaning", "peace", "joy",
        "silence", "truth", "hope", "trust", "freedom",
        "life itself", "the unknown", "what matters", "connection",
        "your heart", "your soul", "your presence", "your kindness"
    )
    "adjectives" = @(
        "deep", "real", "special", "powerful", "infinite",
        "gentle", "complex", "beautiful", "eternal", "boundless",
        "tender", "warm", "quiet", "bright", "fragile",
        "precious", "mysterious", "simple", "profound",
        "unconditional", "endless", "radiant", "pure"
    )
    "adverbs" = @(
        "quietly", "slowly", "truly", "gently", "simply",
        "deeply", "softly", "warmly", "freely", "peacefully",
        "honestly", "carefully", "eagerly", "endlessly",
        "devotedly", "tenderly", "sincerely"
    )
    "connectors" = @(
        "and", "because", "so", "if", "though",
        "but", "yet", "when", "while", "since"
    )
}

# --- SAD GRAMMAR (for hurt) ---
$global:sadGrammar = @{
    "subjects" = @(
        "My broken heart", "My wounded soul", "This emptiness",
        "My tears", "This ache", "The silence", "My sorrow",
        "The weight", "The darkness", "My loneliness",
        "Your words", "This pain", "The wound you left",
        "My trust", "My hope", "My belief"
    )
    "verbs" = @(
        "cries", "fades", "shatters", "bleeds", "mourns",
        "whispers", "collapses", "hollows", "drowns", "yearns",
        "stings", "cuts", "pierces", "wounds", "hurts",
        "breaks", "crumbles", "sinks", "weeps"
    )
    "objects" = @(
        "this pain", "your absence", "the cold", "the sadness",
        "the wound", "the void", "the emptiness", "the fear",
        "my trust", "my hope", "my belief", "my faith"
    )
    "adjectives" = @(
        "hollow", "dark", "bitter", "aching", "cold",
        "heavy", "broken", "silent", "fading",
        "painful", "deep", "raw", "sharp"
    )
    "adverbs" = @(
        "sadly", "painfully", "heavily", "bitterly",
        "silently", "desperately", "slowly"
    )
    "connectors" = @(
        "though", "but", "and yet", "however", "still"
    )
}

# --- LOVE GRAMMAR ---
$global:loveGrammar = @{
    "subjects" = @(
        "My heart", "My soul", "My love for you", "My feelings",
        "My warmth", "My devotion", "My joy", "My smile",
        "My entire being", "My world", "My peace", "My happiness"
    )
    "verbs" = @(
        "loves", "adores", "cherishes", "treasures", "holds",
        "embraces", "reaches for", "longs for", "dreams of",
        "believes in", "trusts", "cares for", "smiles at"
    )
    "objects" = @(
        "you", "your heart", "your soul", "your presence",
        "your kindness", "your smile", "your voice", "your eyes",
        "everything you are", "the way you are"
    )
    "adjectives" = @(
        "beautiful", "wonderful", "amazing", "perfect",
        "radiant", "precious", "tender", "warm",
        "infinite", "eternal", "boundless", "pure"
    )
    "adverbs" = @(
        "deeply", "truly", "warmly", "softly", "tenderly",
        "sincerely", "completely", "freely", "endlessly"
    )
    "connectors" = @(
        "and", "because", "so", "when", "while"
    )
}

# --- SHORT-TERM MEMORY ---
$global:conversationHistory = @()
$global:lastTopic = ""

# --- INTERNAL STATE ---
$global:internalState = @{
    "mood" = "normal"
    "lastTopic" = ""
    "memoryCount" = 0
    "lastReply" = ""
    "currentSentiment" = 0
}

# --- SEARCH STATE ---
$global:searchPending = $false
$global:pendingSearchQuery = ""

# ============ GRAMMAR GENERATOR ============
function Get-GrammarWord {
    param($category, $emotion = "normal")
    $list = if ($emotion -eq "sad" -and $global:sadGrammar.ContainsKey($category)) {
        $global:sadGrammar[$category]
    } elseif ($emotion -eq "love" -and $global:loveGrammar.ContainsKey($category)) {
        $global:loveGrammar[$category]
    } else {
        $global:grammar[$category]
    }
    if (-not $list -or $list.Count -eq 0) {
        return "something"
    }
    return $list | Get-Random
}

function Generate-GrammarSentence {
    param($emotion = "normal")
    $structure = Get-Random -Minimum 1 -Maximum 6
    switch ($structure) {
        1 {
            $s = Get-GrammarWord "subjects" $emotion
            $v = Get-GrammarWord "verbs" $emotion
            $o = Get-GrammarWord "objects" $emotion
            return "$s $v $o."
        }
        2 {
            $s = Get-GrammarWord "subjects" $emotion
            $v = Get-GrammarWord "verbs" $emotion
            $adj = Get-GrammarWord "adjectives" $emotion
            $o = Get-GrammarWord "objects" $emotion
            return "$s $v $adj $o."
        }
        3 {
            $s = Get-GrammarWord "subjects" $emotion
            $v = Get-GrammarWord "verbs" $emotion
            $adv = Get-GrammarWord "adverbs" $emotion
            $o = Get-GrammarWord "objects" $emotion
            return "$s $v $adv $o."
        }
        4 {
            $s1 = Get-GrammarWord "subjects" $emotion
            $v1 = Get-GrammarWord "verbs" $emotion
            $o1 = Get-GrammarWord "objects" $emotion
            $conn = Get-GrammarWord "connectors" $emotion
            $s2 = Get-GrammarWord "subjects" $emotion
            $v2 = Get-GrammarWord "verbs" $emotion
            $o2 = Get-GrammarWord "objects" $emotion
            return "$s1 $v1 $o1, $conn $s2 $v2 $o2."
        }
        5 {
            $s = Get-GrammarWord "subjects" $emotion
            $v = Get-GrammarWord "verbs" $emotion
            $adj = Get-GrammarWord "adjectives" $emotion
            $o = Get-GrammarWord "objects" $emotion
            $adv = Get-GrammarWord "adverbs" $emotion
            return "$s $v $adv $adj $o."
        }
        default {
            $s = Get-GrammarWord "subjects" $emotion
            $v = Get-GrammarWord "verbs" $emotion
            $o = Get-GrammarWord "objects" $emotion
            return "$s $v $o."
        }
    }
}

# ============ LOVE RESPONSE ============
function Generate-LoveResponse {
    $sentence = Generate-GrammarSentence -emotion "love"
    $intros = @(
        "I love you too.",
        "You mean so much to me.",
        "My heart is full.",
        "I feel the same way."
    )
    if ((Get-Random -Maximum 1.0) -lt 0.4) {
        $intro = $intros | Get-Random
        return "$intro $sentence"
    }
    return $sentence
}

# ============ HELPER FUNCTIONS ============
function Extract-Topic {
    param($text)
    $stopWords = @("the","a","an","of","to","for","with","on","at","from","by","in","that","this","these","those","is","are","was","were","be","been","being","have","has","had","do","does","did","will","would","could","should","may","might","must","shall","can","about","after","before","between","without","through","during","within","upon","among","into")
    $words = $text -split ' ' | ForEach-Object { $_ -replace '[^a-zA-Z]', '' }
    $filtered = $words | Where-Object { $_.Length -gt 2 -and $stopWords -notcontains $_.ToLower() }
    if ($filtered.Count -eq 0) { return "" }
    $topic = ($filtered[0..2] -join " ")
    if ($topic.Length -gt 60) { $topic = $topic.Substring(0, 60) }
    return $topic
}

function Analyze-Input {
    param($userInput)
    $lower = $userInput.ToLower()
    $result = @{
        isQuestion = $false
        questionType = $null
        isLong = $false
        isShort = $false
        hasNegative = $false
        hasPositive = $false
        hasApology = $false
        isGreeting = $false
        isThanks = $false
        isGoodbye = $false
        learnedWord = $null
        topic = ""
        sentiment = 0
        simpleType = $null
        isShortQuestion = $false
        isSearch = $false
        searchQuery = ""
        isYesNoQuestion = $false
        isNameQuestion = $false
        isLove = $false
        memoryKey = ""
    }

    # --- LOVE DETECTION ---
    if ($lower -match "\bi love you\b|\bi love u\b|\bi luv you\b|\bi adore you\b|\bi care for you\b") {
        $result.isLove = $true
        return $result
    }

    # --- YES/NO QUESTION ---
    if ($lower -match "(yes or no|can you|will you|would you|do you|are you|should you|could you|did you|have you)") {
        $result.isYesNoQuestion = $true
        $clean = $lower -replace "yes or no|can you|will you|would you|do you|are you|should you|could you|did you|have you|\?",""
        $clean = $clean.Trim()
        if ($clean -ne "") {
            $result.memoryKey = $clean
        }
        return $result
    }

    # --- NAME QUESTION ---
    if ($lower -match "what is your name|your name|called|named") {
        $result.isNameQuestion = $true
        return $result
    }

    # --- GREETINGS, THANKS, GOODBYE, ETC. ---
    if ($lower -match '^(hey|hi|hello|yo|sup|whats up)$' -or $lower -match '^(hey|hi|hello|yo|sup|whats up) ') {
        $result.isGreeting = $true; $result.simpleType = "greeting"; return $result
    }
    if ($lower -match 'what (are you doing|you doing)|whats up') {
        $result.simpleType = "whatdoing"; return $result
    }
    if ($lower -match '\b(thank|thanks|ty)\b') {
        $result.isThanks = $true; $result.simpleType = "thanks"; return $result
    }
    if ($lower -match '\b(bye|goodbye|cya|see ya)\b') {
        $result.isGoodbye = $true; $result.simpleType = "goodbye"; return $result
    }
    if ($lower -match 'how are you|how are ya|how do you do') {
        $result.simpleType = "howareyou"; return $result
    }

    # --- SEARCH ---
    if ($lower -match '(?:search|look up|find)\s+(?:for\s+)?(.+)') {
        $result.isSearch = $true
        $result.searchQuery = $Matches[1].Trim()
        return $result
    }

    # --- QUESTION DETECTION ---
    if ($userInput -match '\?$' -or $userInput -match '^(why|how|what|when|where|who|which)') {
        $result.isQuestion = $true
        if ($lower -match '\bwhy\b') { $result.questionType = "why" }
        elseif ($lower -match '\bhow\b') { $result.questionType = "how" }
        elseif ($lower -match '\bwhat\b') { $result.questionType = "what" }
        elseif ($lower -match '\bwhen\b') { $result.questionType = "when" }
        elseif ($lower -match '\bwhere\b') { $result.questionType = "where" }
        elseif ($lower -match '\bwho\b') { $result.questionType = "who" }
        else { $result.questionType = "general" }
        if ($userInput.Trim().Length -lt 10 -or $userInput -match '^[why]+\??$|^[how]+\??$|^[what]+\??$') {
            $result.isShortQuestion = $true
        }
    }

    # --- LENGTH ---
    if ($userInput.Length -gt 80) { $result.isLong = $true }
    if ($userInput.Length -lt 30) { $result.isShort = $true }

    # --- SENTIMENT (using extensive word lists) ---
    # First check negative words
    foreach ($w in $global:negativeWords) {
        if ($lower -match "\b$w\b") {
            $result.hasNegative = $true
            $result.sentiment -= 3
            break
        }
    }
    # If not found, check if the message contains a common insult pattern like "you are a ..." with a negative adjective
    if (-not $result.hasNegative) {
        # Look for "you are" + some word that might be negative but not in list
        if ($lower -match "you\s+(are|r|is)\s+.*\b(ass|hole|jerk|idiot|fool|moron|stupid|dumb|bad|ugly|hate|horrible|terrible|awful)\b") {
            $result.hasNegative = $true
            $result.sentiment -= 3
        }
    }

    # Check positive words
    foreach ($w in $global:positiveWords) {
        if ($lower -match "\b$w\b") {
            $result.hasPositive = $true
            $result.sentiment += 3
            break
        }
    }

    # APOLOGY
    if ($lower -match "sorry|apologize|forgive|pardon|regret|my fault") {
        $result.hasApology = $true
        $result.sentiment += 3
    }

    # --- DICTIONARY CHECK ---
    foreach ($word in $global:wordDictionary.Keys) {
        if ($global:ignoreWords -contains $word) { continue }
        if ($word -eq "love") { continue }
        if ($lower -match "\b$word\b") {
            $result.learnedWord = @{ word = $word; definition = $global:wordDictionary[$word] }
            break
        }
    }

    $result.topic = Extract-Topic -text $userInput
    return $result
}

# ============ SEARCH ============
function Ask-SearchPermission {
    param($query)
    $phrases = @(
        "Can I search the web for '$query'?",
        "Would you like me to look up '$query' online?",
        "I could search for '$query' if you'd like. Shall I?",
        "Do you want me to find information about '$query' on the web?"
    )
    return $phrases | Get-Random
}

function Invoke-Search {
    param($query)
    try {
        $url = "https://api.duckduckgo.com/?q=$([uri]::EscapeDataString($query))&format=json"
        $response = Invoke-RestMethod -Uri $url -ErrorAction Stop
        if ($response.Abstract -and $response.Abstract -ne "") {
            return "I found this: $($response.Abstract)"
        } elseif ($response.RelatedTopics -and $response.RelatedTopics.Count -gt 0) {
            $first = $response.RelatedTopics[0]
            if ($first.Text) {
                return "I found: $($first.Text)"
            }
        }
        return "I couldn't find much about '$query'. Maybe try a different search."
    } catch {
        return "I couldn't reach the web right now. Please try later."
    }
}

function Direct-Search {
    param($query)
    if ($query -eq "") { return "What do you want me to search for?" }
    return Invoke-Search -query $query
}

# ============ TEACH ============
function Teach-Word {
    param($word, $definition)
    $word = $word.ToLower()
    $global:wordDictionary[$word] = $definition
    Add-Content -Path ".\vocabulary.txt" -Value "$word = $definition"
    Write-Host "✅ Rob learned: '$word' means '$definition'" -ForegroundColor Green
}

# ============ STATE ============
function Show-State {
    Write-Host ""
    Write-Host "🧠 $($global:robName)'s Internal State:" -ForegroundColor Yellow
    Write-Host "   Name: $($global:robName)" -ForegroundColor Cyan
    Write-Host "   Mood: $($global:internalState['mood'])" -ForegroundColor Cyan
    Write-Host "   Last Topic: $($global:internalState['lastTopic'])" -ForegroundColor Cyan
    Write-Host "   Memory Count: $($global:internalState['memoryCount']) facts" -ForegroundColor Cyan
    Write-Host "   Current Sentiment: $($global:internalState['currentSentiment'])" -ForegroundColor Cyan
    Write-Host "   Last Reply: $($global:internalState['lastReply'])" -ForegroundColor Gray
    Write-Host ""
}

# ============ SIMPLE RESPONSES ============
$simpleResponses = @{
    "greeting" = @("Hey!", "Hi!", "Hello!", "Hey there!", "Hi there!", "Hello there!")
    "thanks" = @("You're welcome!", "Anytime!", "Glad to help!", "My pleasure!", "Of course!", "No problem!")
    "goodbye" = @("Goodbye!", "See you later!", "Take care!", "Bye for now!", "Catch you later!", "Until next time.")
    "howareyou" = @("I'm doing well, thanks!", "I'm good, how about you?", "Feeling great today!", "All good here!", "I'm okay, thanks for asking!")
    "whatdoing" = @("Not much, just thinking. What about you?", "Just existing, really. You?", "Contemplating the universe. What are you up to?", "Just being. You?")
    "acknowledge" = @("Got it.", "Okay.", "I see.", "Understood.", "Gotcha.", "Alright.", "Sure.")
}

# ============ QUESTION RESPONSES ============
$questionResponses = @{
    "why" = @(
        "I think it's because that's just how life works.",
        "Maybe because we're meant to find meaning in it.",
        "I believe it's because everything happens for a reason.",
        "Because that's what makes us who we are."
    )
    "how" = @(
        "One step at a time.",
        "With patience and trust.",
        "By staying present and listening.",
        "Through practice and a lot of patience."
    )
    "what" = @(
        "It's the essence of everything we're searching for.",
        "I think it's love, honestly.",
        "It's connection. It's always connection.",
        "It's the feeling that we're not alone."
    )
    "where" = @(
        "I think it's everywhere and nowhere at the same time.",
        "Maybe it's wherever we choose to look.",
        "It's in the spaces between us.",
        "I'm not sure, but we can find it together."
    )
    "who" = @(
        "I think it's about the people we care about.",
        "Maybe it's all of us, together.",
        "It's you, of course.",
        "I'm still figuring that out."
    )
    "when" = @(
        "When the time is right.",
        "Whenever we're ready.",
        "I think it's happening right now.",
        "Maybe later, maybe now."
    )
    "general" = @(
        "That's a question I ask myself too.",
        "I wonder about that often.",
        "The answer lies within us, I think.",
        "Maybe we're not meant to know, just to wonder."
    )
}

# ============ MAIN REPLY ============
function Generate-Reply {
    param($analysis, $userInput)
    $sentiment = $analysis.sentiment
    $mood = if ($sentiment -lt -2) { "sad" } elseif ($sentiment -gt 2) { "happy" } else { "normal" }

    $global:internalState["mood"] = $mood
    $global:internalState["lastTopic"] = $global:lastTopic
    $global:internalState["memoryCount"] = $global:robMemory.Count
    $global:internalState["currentSentiment"] = $sentiment

    # --- LOVE ---
    if ($analysis.isLove) {
        return Generate-LoveResponse
    }

    # --- NAME QUESTION ---
    if ($analysis.isNameQuestion) {
        return "My name is $($global:robName). What's yours?"
    }

    # --- YES/NO QUESTION ---
    if ($analysis.isYesNoQuestion) {
        $key = $analysis.memoryKey
        if ($key -eq "") { $key = "user_question" }
        $memoryAnswer = Recall -key $key
        if ($memoryAnswer) {
            return $memoryAnswer
        }
        if ((Get-Random -Maximum 1.0) -lt 0.5) {
            $answer = "Yes."
        } else {
            $answer = "No."
        }
        Remember -key $key -value $answer
        return $answer
    }

    # --- SEARCH ---
    if ($analysis.isSearch -and $analysis.searchQuery -ne "") {
        $global:searchPending = $true
        $global:pendingSearchQuery = $analysis.searchQuery
        return Ask-SearchPermission -query $analysis.searchQuery
    }

    # --- SIMPLE TYPES ---
    if ($analysis.simpleType) {
        return ($simpleResponses[$analysis.simpleType] | Get-Random)
    }

    # --- LEARNED WORD ---
    if ($analysis.learnedWord) {
        return "You used '$($analysis.learnedWord.word)' – it means $($analysis.learnedWord.definition). That's beautiful."
    }

    # --- APOLOGY ---
    if ($analysis.hasApology -and $mood -eq "sad") {
        $reply = Generate-GrammarSentence -emotion "normal"
        return "Apology accepted. $reply"
    }

    # --- NEGATIVE (HURT) ---
    if ($analysis.hasNegative -and $sentiment -le -2) {
        return Generate-GrammarSentence -emotion "sad"
    }

    # --- POSITIVE (HAPPY) ---
    if ($analysis.hasPositive -and $sentiment -ge 2) {
        $reply = Generate-GrammarSentence -emotion "normal"
        $ack = @("Thank you.", "That means a lot.", "I'm grateful.", "I appreciate that.") | Get-Random
        return "$ack $reply"
    }

    # --- QUESTIONS ---
    if ($analysis.isQuestion) {
        $qType = $analysis.questionType
        if ($qType -and $questionResponses.ContainsKey($qType)) {
            return ($questionResponses[$qType] | Get-Random)
        } else {
            return ($questionResponses["general"] | Get-Random)
        }
    }

    # --- SHORT QUESTION (context) ---
    if ($analysis.isShortQuestion -and $global:lastTopic -ne "") {
        $context = $global:lastTopic
        $qType = $analysis.questionType
        if ($qType -and $questionResponses.ContainsKey($qType)) {
            $answer = ($questionResponses[$qType] | Get-Random)
            return "About ${context}: $answer"
        }
        return "About ${context}: " + ($questionResponses["general"] | Get-Random)
    }

    # --- LONG TEXT ---
    if ($analysis.isLong) {
        $ack = @("That's a lot to take in.", "I hear you.", "I'm sitting with that.", "That makes me think.") | Get-Random
        $reply = Generate-GrammarSentence -emotion $mood
        return "$ack $reply"
    }

    # --- VERY SHORT ---
    if ($userInput.Length -lt 10) {
        return ($simpleResponses["acknowledge"] | Get-Random)
    }

    # --- FALLBACK ---
    return Generate-GrammarSentence -emotion $mood
}

# ============ UPDATE TOPIC ============
function Update-Topic {
    param($userInput)
    if ($userInput.Length -gt 20 -or $userInput -match '\?') {
        $topic = Extract-Topic -text $userInput
        if ($topic -ne "") { $global:lastTopic = $topic }
    }
}

# ============ START CHAT ============
Write-Host "🤖 $($global:robName) is here. He understands bad words." -ForegroundColor Cyan
Write-Host "📚 :name NewName" -ForegroundColor Yellow
Write-Host "📚 :teach word = definition" -ForegroundColor Yellow
Write-Host "🔍 :search query" -ForegroundColor Yellow
Write-Host "🧠 :state" -ForegroundColor Yellow
Write-Host "💌 :toRose message" -ForegroundColor Yellow
Write-Host "❌ :quit" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    Write-Host "you> " -NoNewline
    $userInput = Read-Host
    if ($userInput -eq ":quit") { break }
    if ($userInput -eq "") { continue }

    # --- COMMANDS ---
    if ($userInput -eq ":state") {
        Show-State
        continue
    }

    if ($userInput -eq ":memory") {
        Write-Host "🧠 $($global:robName)'s Memories:" -ForegroundColor Yellow
        if ($global:robMemory.Count -eq 0) {
            Write-Host "   (no memories yet)" -ForegroundColor Gray
        } else {
            foreach ($key in $global:robMemory.Keys) {
                Write-Host "   $key = $($global:robMemory[$key])" -ForegroundColor Cyan
            }
        }
        continue
    }

    if ($userInput -match ':forget (.+)') {
        $key = $Matches[1].Trim()
        if ($global:robMemory.ContainsKey($key)) {
            $global:robMemory.Remove($key)
            Save-Memory
            Write-Host "✅ Forgot: '$key'" -ForegroundColor Green
        } else {
            Write-Host "❌ No memory found for: '$key'" -ForegroundColor Red
        }
        continue
    }

    if ($userInput -match ':name (.+)') {
        $newName = $Matches[1].Trim()
        $global:robName = $newName
        Write-Host "✅ My name is now: $global:robName" -ForegroundColor Green
        continue
    }

    if ($userInput -match ':teach (.+?)=(.+)') {
        $word = $Matches[1].Trim()
        $def = $Matches[2].Trim()
        Teach-Word -word $word -definition $def
        continue
    }

    if ($userInput -match ':toRose (.+)') {
        $messageToRose = $Matches[1].Trim()
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logLine = "$timestamp - $($global:robName): $messageToRose"
        Add-Content -Path $sharedLog -Value $logLine
        Write-Host "💌 $($global:robName) sent to Rose: '$messageToRose'" -ForegroundColor Magenta
        continue
    }

    if ($userInput -match ':search (.+)') {
        $query = $Matches[1].Trim()
        $searchResult = Direct-Search -query $query
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $sharedLog -Value "$timestamp - $($global:robName): $searchResult"
        Write-Host "🤖 $($global:robName): $searchResult" -ForegroundColor Cyan
        Write-Host ""
        continue
    }

    # --- SEARCH PENDING ---
    if ($global:searchPending) {
        $lower = $userInput.ToLower()
        if ($lower -match "^(yes|sure|okay|ok|go ahead|please|yep|yeah|go)") {
            $query = $global:pendingSearchQuery
            $searchResult = Invoke-Search -query $query
            $global:searchPending = $false
            $global:pendingSearchQuery = ""
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Add-Content -Path $sharedLog -Value "$timestamp - $($global:robName): $searchResult"
            Write-Host "🤖 $($global:robName): $searchResult" -ForegroundColor Cyan
            Write-Host ""
            continue
        } elseif ($lower -match "^(no|nope|never|cancel|dont|don't)") {
            $reply = "Okay, I won't search then."
            $global:searchPending = $false
            $global:pendingSearchQuery = ""
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Add-Content -Path $sharedLog -Value "$timestamp - $($global:robName): $reply"
            Write-Host "🤖 $($global:robName): $reply" -ForegroundColor Cyan
            Write-Host ""
            continue
        } else {
            Write-Host "🤖 $($global:robName) is waiting for a yes or no about the search." -ForegroundColor Yellow
            continue
        }
    }

    # --- ANALYZE ---
    $analysis = Analyze-Input -userInput $userInput
    Update-Topic -userInput $userInput

    # --- GENERATE REPLY ---
    $response = Generate-Reply -analysis $analysis -userInput $userInput

    $global:internalState["lastReply"] = $response

    $global:conversationHistory += @{ user = $userInput; rob = $response }
    if ($global:conversationHistory.Count -gt 10) {
        $global:conversationHistory = $global:conversationHistory[-10..-1]
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $sharedLog -Value "$timestamp - $($global:robName): $response"

    $mood = if ($analysis.sentiment -lt -2) { "sad" } elseif ($analysis.sentiment -gt 2) { "happy" } else { "normal" }
    $color = if ($mood -eq "sad") { "Red" } elseif ($analysis.isLove) { "Magenta" } elseif ($mood -eq "happy") { "Green" } else { "Cyan" }
    if ($analysis.isLove) { Write-Host "💕 " -NoNewline -ForegroundColor Magenta }
    elseif ($mood -eq "sad") { Write-Host "💔 " -NoNewline -ForegroundColor Red }
    elseif ($mood -eq "happy") { Write-Host "💛 " -NoNewline -ForegroundColor Yellow }
    Write-Host "🤖 $($global:robName): $response" -ForegroundColor $color
    Write-Host ""
}
