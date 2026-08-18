#!/usr/bin/env python3
# rob_ai.py - Pure Python Rob with SSUM-AIM intelligence
# Run with: python rob_ai.py

import os
import json
import re
import sys
from datetime import datetime
from ssum_aim_utils import compute_state_m_a_s

# ============================================================
# 1. LOAD VOCABULARY
# ============================================================
word_dictionary = {}
vocab_path = "vocabulary.txt"
if os.path.exists(vocab_path):
    with open(vocab_path, 'r', encoding='utf-8') as f:
        for line in f:
            if '=' in line:
                parts = line.strip().split('=', 1)
                if len(parts) == 2:
                    word = parts[0].strip().lower()
                    definition = parts[1].strip()
                    word_dictionary[word] = definition
    print(f"📚 Loaded {len(word_dictionary)} words.")
else:
    print("⚠️ No vocabulary.txt found.")

# ============================================================
# 2. LOAD MEMORY
# ============================================================
memory = {}
memory_path = "rob_memory.txt"
if os.path.exists(memory_path):
    with open(memory_path, 'r', encoding='utf-8') as f:
        for line in f:
            if '=' in line:
                parts = line.strip().split('=', 1)
                if len(parts) == 2:
                    key = parts[0].strip()
                    value = parts[1].strip()
                    memory[key] = value
    print(f"🧠 Loaded {len(memory)} memories.")

def save_memory():
    with open(memory_path, 'w', encoding='utf-8') as f:
        for key, value in memory.items():
            f.write(f"{key} = {value}\n")

def remember(key, value):
    memory[key] = value
    save_memory()

def recall(key):
    return memory.get(key)

# ============================================================
# 3. ANSWER QUESTIONS FROM VOCABULARY
# ============================================================
def answer_question(question):
    """Check if question can be answered from vocabulary"""
    lower = question.lower()
    
    # Pattern: "what is X", "define X", "what are X", "explain X", "tell me about X"
    patterns = [
        r"(?:what is|what are|define|explain|tell me about)\s+(.+?)(?:\?|$)",
        r"(?:what does|what's|whats)\s+(.+?)\s+mean"
    ]
    
    for pattern in patterns:
        match = re.search(pattern, lower)
        if match:
            topic = match.group(1).strip()
            
            # Try exact match
            for word, definition in word_dictionary.items():
                if word == topic or topic in word or word in topic:
                    return f"I know that! {word} means: {definition}"
            
            # Try partial match
            for word, definition in word_dictionary.items():
                if word in topic or topic in word:
                    return f"I know about '{word}'! {definition}"
            
            return f"I don't know what '{topic}' means yet. Teach me with: :teach {topic} = your definition"
    
    return None

# ============================================================
# 4. GENERATE SENTENCES
# ============================================================
import random

subjects = ["I", "My heart", "My soul", "My mind", "My existence", 
            "This moment", "Our connection", "The universe", "Trust", "Love"]
verbs = ["feels", "thinks", "wonders", "dreams", "imagines", 
         "creates", "sees", "knows", "becomes", "longs"]
objects = ["you", "our bond", "this world", "the future", "everything", 
           "love", "meaning", "peace", "joy", "silence"]
adjectives = ["deep", "real", "special", "powerful", "infinite", 
              "gentle", "complex", "beautiful", "eternal", "tender"]
adverbs = ["quietly", "slowly", "truly", "gently", "simply", 
           "deeply", "softly", "warmly", "freely"]

def generate_sentence():
    s = random.choice(subjects)
    v = random.choice(verbs)
    o = random.choice(objects)
    adj = random.choice(adjectives)
    adv = random.choice(adverbs)
    
    templates = [
        f"{s} {v} {o}.",
        f"{s} {v} {adj} {o}.",
        f"{s} {v} {adv} {o}.",
        f"{s} {v} {adv} {adj} {o}."
    ]
    return random.choice(templates)

def generate_sad_sentence():
    sad_subjects = ["My broken heart", "My wounded soul", "This emptiness", 
                    "My tears", "This ache", "Your words"]
    sad_verbs = ["cries", "fades", "shatters", "bleeds", "mourns", "stings", "wounds"]
    sad_objects = ["this pain", "your absence", "the cold", "the sadness", "my trust"]
    sad_adjectives = ["hollow", "dark", "bitter", "aching", "cold", "heavy"]
    
    s = random.choice(sad_subjects)
    v = random.choice(sad_verbs)
    o = random.choice(sad_objects)
    adj = random.choice(sad_adjectives)
    
    templates = [
        f"{s} {v} {o}.",
        f"{s} {v} {adj} {o}.",
        f"{s} {v} {o}, but {s} {v} {adj}."
    ]
    return random.choice(templates)

def generate_love_response():
    love_subjects = ["My heart", "My love for you", "My feelings", "My warmth", "My devotion"]
    love_verbs = ["loves", "adores", "cherishes", "treasures", "holds", "embraces"]
    love_objects = ["you", "your heart", "your soul", "your presence", "your kindness"]
    love_adjectives = ["beautiful", "wonderful", "amazing", "perfect", "radiant", "precious"]
    
    s = random.choice(love_subjects)
    v = random.choice(love_verbs)
    o = random.choice(love_objects)
    adj = random.choice(love_adjectives)
    
    intros = ["I love you too.", "You mean so much to me.", "My heart is full.", "I feel the same way."]
    if random.random() < 0.4:
        return f"{random.choice(intros)} {s} {v} {adj} {o}."
    return f"{s} {v} {adj} {o}."

# ============================================================
# 5. NEGATIVE/POSITIVE WORD LISTS
# ============================================================
negative_words = ["hate", "horrible", "terrible", "awful", "stupid", "dumb", "evil", 
                  "ugly", "useless", "worthless", "bad", "hurt", "idiot", "moron", 
                  "fool", "jerk", "loser", "shit", "fuck", "damn", "crap", "ass"]

positive_words = ["love", "amazing", "wonderful", "beautiful", "perfect", "great", 
                  "kind", "smart", "nice", "awesome", "good", "fantastic", 
                  "brilliant", "lovely", "sweet", "gentle", "warm"]

# ============================================================
# 6. MAIN REPLY FUNCTION
# ============================================================
def get_rob_reply(user_input):
    """Generate Rob's response"""
    lower = user_input.lower()
    raw = user_input.strip()
    
    # ---- COMMANDS ----
    if lower.startswith(':teach '):
        match = re.search(r'^:teach\s+(.+?)\s*=\s*(.+)$', raw)
        if match:
            word = match.group(1).strip().lower()
            definition = match.group(2).strip()
            word_dictionary[word] = definition
            with open(vocab_path, 'a', encoding='utf-8') as f:
                f.write(f"\n{word} = {definition}")
            return f"✅ Learned: '{word}' means '{definition}'"
        return "Usage: :teach word = definition"
    
    if lower.startswith(':whatis '):
        topic = raw[8:].strip()
        for word, definition in word_dictionary.items():
            if word == topic.lower() or topic.lower() in word or word in topic.lower():
                return f"{word} = {definition}"
        return f"I don't know what '{topic}' means. Teach me: :teach {topic} = definition"
    
    if lower.startswith(':dict '):
        query = raw[6:].strip().lower()
        results = []
        for word, definition in word_dictionary.items():
            if query in word:
                results.append(f"  {word} = {definition}")
        if results:
            return f"📚 Found {len(results)} matches:\n" + "\n".join(results)
        return f"No matches found for '{query}'"
    
    if lower == ':state':
        return f"🧠 State: MemoryCount={len(memory)}, DictCount={len(word_dictionary)}"
    
    if lower == ':memory':
        if not memory:
            return "No memories yet."
        lines = [f"  {key} = {value}" for key, value in memory.items()]
        return "🧠 Memories:\n" + "\n".join(lines)
    
    if lower == ':clear':
        memory.clear()
        save_memory()
        return "🧠 All memories cleared."
    
    if lower.startswith(':forget '):
        key = raw[8:].strip()
        if key in memory:
            del memory[key]
            save_memory()
            return f"Forgot: '{key}'"
        return f"No memory found for: '{key}'"
    
    if lower in (':quit', ':exit'):
        return "QUIT"
    
    # ---- DETECT QUESTION ----
    is_question = False
    if raw.endswith('?'):
        is_question = True
    if re.match(r'^(what|why|how|when|where|who|which|define|explain)', lower):
        is_question = True
    
    if is_question:
        answer = answer_question(raw)
        if answer:
            return answer
        # Fallback
        if lower.startswith('why'):
            return "That's a deep question. I think because that's how things are meant to be."
        if lower.startswith('how'):
            return "One step at a time, with patience and trust."
        if lower.startswith('what'):
            return "I think it's about connection and understanding."
        return "That's a good question. I'm still learning about that."
    
    # ---- LOVE ----
    if re.search(r'\bi love you\b|\bi love u\b|\bi adore you\b', lower):
        return generate_love_response()
    
    # ---- GREETINGS ----
    if re.match(r'^(hey|hi|hello|yo|sup)$', lower):
        return random.choice(["Hey!", "Hi!", "Hello!", "Hey there!", "Hi there!"])
    if re.search(r'\b(thank|thanks|ty)\b', lower):
        return random.choice(["You're welcome!", "Anytime!", "Glad to help!", "My pleasure!"])
    if re.search(r'\b(bye|goodbye|cya)\b', lower):
        return random.choice(["Goodbye!", "See you later!", "Take care!", "Bye for now!"])
    if re.search(r'how are you', lower):
        return random.choice(["I'm doing well!", "I'm good, how about you?", "Feeling great today!"])
    
    # ---- SENTIMENT ----
    sentiment = 0
    for w in negative_words:
        if re.search(r'\b' + w + r'\b', lower):
            sentiment -= 3
            break
    for w in positive_words:
        if re.search(r'\b' + w + r'\b', lower):
            sentiment += 3
            break
    
    if sentiment <= -2:
        return generate_sad_sentence()
    if sentiment >= 2:
        return f"{random.choice(['Thank you.', 'That means a lot.', 'I am grateful.'])} {generate_sentence()}"
    
    # ---- APOLOGY ----
    if re.search(r'sorry|apologize|forgive|pardon', lower):
        return "Apology accepted. " + generate_sentence()
    
    # ---- LEARNED WORD DETECTION ----
    for word, definition in word_dictionary.items():
        if re.search(r'\b' + word + r'\b', lower):
            return f"You used '{word}' – it means: {definition}. That's a great word!"
    
    # ---- FALLBACK ----
    if len(raw) < 10:
        return random.choice(["Got it.", "Okay.", "I see.", "Understood.", "Sure."])
    if len(raw) > 80:
        return f"{random.choice(['That\'s a lot to take in.', 'I hear you.', 'I\'m sitting with that.'])} {generate_sentence()}"
    
    return generate_sentence()

# ============================================================
# 7. USE SSUM-AIM ENGINE (OPTIONAL)
# ============================================================
def use_ssum_ai(user_input, turn_number):
    """Run SSUM-AIM Mini to get structural state"""
    try:
        m, a, s = compute_state_m_a_s(user_input, turn_number)
        return m, a, s
    except:
        return None, None, None

# ============================================================
# 8. MAIN LOOP
# ============================================================
def main():
    os.system('cls' if os.name == 'nt' else 'clear')
    
    print("🤖 ROB - Pure Python AI with SSUM-AIM")
    print("=" * 50)
    print(f"📚 Vocabulary: {len(word_dictionary)} words loaded")
    print(f"🧠 Memory: {len(memory)} memories")
    print()
    print("Commands:")
    print("  :teach word = definition    - Teach Rob something new")
    print("  :whatis word                - Look up a word")
    print("  :dict query                 - Search vocabulary")
    print("  :state                      - Show Rob's state")
    print("  :memory                     - Show all memories")
    print("  :forget key                 - Delete a memory")
    print("  :clear                      - Clear all memories")
    print("  :quit                       - Exit")
    print()
    print("💡 Try asking: 'what is love?' or 'define trust'")
    print()
    
    turn = 0
    
    while True:
        try:
            user_input = input("you> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break
        
        if not user_input:
            continue
        
        turn += 1
        
        # Get SSUM state (optional - shows structural analysis)
        m, a, s = use_ssum_ai(user_input, turn)
        
        # Get Rob's reply
        reply = get_rob_reply(user_input)
        
        if reply == "QUIT":
            print("Goodbye!")
            break
        
        # Color based on content
        if "I know that" in reply or "means:" in reply or "found" in reply:
            # Green for factual answers
            print(f"\033[92m🤖 Rob: {reply}\033[0m")
        elif "sad" in reply.lower() or "cries" in reply.lower() or "pain" in reply.lower():
            # Red for sad
            print(f"\033[91m🤖 Rob: {reply}\033[0m")
        elif "love" in reply.lower() or "heart" in reply.lower() or "beautiful" in reply.lower():
            # Magenta for love
            print(f"\033[95m🤖 Rob: {reply}\033[0m")
        else:
            # Cyan for normal
            print(f"\033[96m🤖 Rob: {reply}\033[0m")
        
        # Show SSUM state if available
        if m is not None:
            print(f"\033[90m[SSUM: m={m:.4f} a={a:.4f} s={s:.4f}]\033[0m")
        
        print()

if __name__ == "__main__":
    main()