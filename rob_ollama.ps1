
    param($userInput)
    $r = $userInput.Trim()
    $turnCount++
    
    # ---- COMMANDS ----
    if ($r -eq ':state') {
        $ssum = Get-SSUM -userInput $r
        return "SSUM: m=$($ssum.m) a=$($ssum.a) s=$($ssum.s) | Source: $($ssum.source) | Turns: $turnCount | Knowledge: $($knowledge.Count)"
    }
    if ($r -eq ':memory') {
        if ($chatHistory.Count -eq 0) { return "No memory yet." }
        $lines = @()
        for ($i = [Math]::Max(0, $chatHistory.Count - 10); $i -lt $chatHistory.Count; $i++) {
            $lines += "  $($chatHistory[$i])"
        }
        return "Recent conversation:`n$($lines -join "`n")"
    }
    if ($r -eq ':clear') { $chatHistory = @{}; return "Memory cleared." }
    if ($r -eq ':clearall') { $knowledge = @{}; $chatHistory = @{}; Save-Data; return "Everything cleared." }
    if ($r -eq ':quit' -or $r -eq ':exit') { return "QUIT" }
    
    # ---- SAVE TO HISTORY ----
    $chatHistory += "User: $r"
    if ($chatHistory.Count -gt 50) { $chatHistory = $chatHistory[-50..-1] }
    $global:lastUserMessage = $r
    
    # ---- GET SSUM ----
    $ssum = Get-SSUM -userInput $r
    
    # ---- THINK ----
    $reply = Rob-Think -userInput $r -ssum $ssum
    
    # ---- SAVE RESPONSE ----
    $chatHistory += "Rob: $reply"
    
    # ---- SHOW ----
$stateLine = ""
    return $reply

