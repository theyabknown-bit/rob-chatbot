# SSUM-AIM Mini

## Artificial Intelligence Manifest (Mini Edition)

![Open Standard](https://img.shields.io/badge/License-Open%20Standard-brightgreen) ![GitHub Repo stars](https://img.shields.io/github/stars/OMPSHUNYAYA/SSUM-AIM-Mini?style=flat&color=brightgreen)

A **tiny (~14 KB)**, transparent, deterministic, offline **AI reflection kernel**  
built using **Shunyaya Structural Universal Mathematics (SSUM)**,  
with **manifest-first behavior** and **guaranteed classical collapse**,  
where every state transition is **explicit and verifiable**.

---

## What is SSUM-AIM Mini?

SSUM-AIM Mini is a **fully local, manifest-driven AI console** designed to show that meaningful AI behavior does **not** require:

- large models  
- cloud services  
- training data  
- hidden inference  
- probabilistic guessing  

Instead, it demonstrates a different class of AI:

**Structural, symbolic, deterministic intelligence**  
that is transparent, auditable, and user-controlled.

SSUM-AIM Mini is an **Artificial Intelligence Manifest (AIM)**  
built using **Shunyaya Structural Universal Mathematics (SSUM)** —  
a framework focused on **structure, movement, and cost of change**,  
rather than prediction or probability.

---

## 🔗 **Quick Links**

### 📘 **Documentation**
- [docs/FAQ.md](docs/FAQ.md) — Design choices, structural distance, and manifest behavior
- [docs/Examples.md](docs/Examples.md) — Verbatim example sessions and interpretations
- [docs/TestAndRunGuide.md](docs/TestAndRunGuide.md) — Step-by-step test and run workflow (Windows CMD)

### 🧪 **Core Scripts**
- [scripts/ssum_aim_core.py](scripts/ssum_aim_core.py) — SSUM-AIM Mini console engine
- [scripts/ssum_aim_utils.py](scripts/ssum_aim_utils.py) — Structural math, distance, and verification utilities

### 📄 **License**
- [LICENSE](LICENSE) — Open Standard License (permissive, no registration, no fees)

---

## Key properties (at a glance)

- **~14 KB** total engine size (core + utils, plain Python)
- **Offline-only** (no internet, no APIs, no telemetry)
- **Stdlib-only** (zero dependencies)
- **Deterministic** (same input + same history → same result)
- **Manifest-first** (all state visible in `memory.json`)
- **Tamper-evident** (SHA-256 hash printed every turn)

---

## Non-advisory, non-neural clarification

SSUM-AIM Mini is **reflection-only and non-advisory**.  
It must **not** be used for decisions, automation, prediction, or control.

SSUM-AIM Mini is **not** a chatbot, not a neural network, and not a language model.

It is **not based on** neural networks, machine learning, deep learning,  
transformers, embeddings, training data, or probabilistic inference.

It does **not** predict text, sample probabilities, adapt weights,  
or learn behavior over time.

All behavior arises from **explicit structural rules**  
and **deterministic mathematics**, implemented in plain Python.

SSUM-AIM Mini is a **structural reflection kernel**,  
not an advisory or generative AI.

---

## What does “AI Manifest” mean?

**AIM = Artificial Intelligence Manifest**

In SSUM-AIM Mini, *manifest* means:

- behavior is **explicit**, not implied  
- logic is **visible**, not hidden  
- state is **logged**, not inferred  
- change is **measured**, not guessed  

Every interaction:

- produces a structural state  
- is written to a local manifest (`memory.json`)  
- is cryptographically verifiable  
- can be replayed and audited  

Nothing happens “inside a model.”  
Everything happens **in the open**.

---

## Core idea (in one sentence)

SSUM-AIM Mini observes how thinking moves over time  
using **symbolic structure and measurable distance** —  
not probability or prediction.

---

## What SSUM adds (important for new users)

### SSM vs SSUM (simple explanation)

**SSM — Shunyaya Symbolic Mathematics**  
Describes **state**.

**SSUM — Shunyaya Structural Universal Mathematics**  
Describes **movement between states**.

SSUM-AIM Mini uses **SSUM**, not just SSM.

That means it tracks:

- where you are now  
- how you moved here  
- how costly that movement was  

---

## The structural state `(m, a, s)`

Every user message is converted into a symbolic state:

`(m, a, s)`

Where:

- `m` → classical mirror value (always preserved)
- `a` → alignment / permission signal in (-1, +1)
- `s` → suppression / resistance signal in (-1, +1)

A guaranteed rule always holds:

`phi((m, a, s)) = m`

Meaning:

- symbolic channels never overwrite classical meaning  
- collapse is safe and deterministic  

---

## Structural Distance (the SSUM part)

SSUM-AIM Mini does not only record states —  
it computes **structural distance between states**.

### Turn semantics (canonical)

- On **Turn 1**, distance is measured from a fixed implicit baseline posture defined by the engine.  
- From **Turn 2 onward**, distance is measured between consecutive states.

This ensures the first interaction already has **real structural cost**,  
rather than being treated as a zero-movement initialization step.

Conceptually:

`u = atanh(a)`  
`v = atanh(s)`

`D_k = sqrt( (dm)^2 + (du)^2 + (dv)^2 )`

From this, the system derives:

- classical path length  
- structural path length  
- efficiency ratio `eta`  
- resistance and pressure indicators  

This allows deterministic observations such as:

- “cost is rising faster than progress”
- “resistance is higher this turn”
- “movement stabilized”

---

## What SSUM-AIM Mini is NOT

It is **not**:

- a chatbot  
- a language model  
- a predictor  
- a recommender  
- a planner  
- a decision system  
- a learning system  
- a cloud service  

It will **not**:

- guess facts  
- hallucinate answers  
- infer personal data  
- adapt its behavior secretly  

---

## What SSUM-AIM Mini IS good for

- personal reflection  
- journaling with structure  
- observing thinking patterns  
- learning transparent AI design  
- teaching symbolic intelligence  
- experimenting with manifest-based AI  
- verifying AI behavior end-to-end  

---

## Quick start

### Requirements

- Python **3.8+**

### Files (one folder)

- `ssum_aim_core.py`
- `ssum_aim_utils.py`
- `test_aim_utils.py` (optional)

### Run tests (recommended)

`python test_aim_utils.py`

If all blocks end with **OK**, the system is ready.

---

## Launch SSUM-AIM Mini

`python ssum_aim_core.py`

You will see:

SSUM-AIM (Mini) — Artificial Intelligence Manifest  
Built using Shunyaya Structural Universal Mathematics (SSUM)

- Fully local • Offline • Deterministic • Stdlib-only  
- Manifest-first behavior (no hidden training, no cloud)  
- Guarantees classical collapse: `phi((m,a,s)) = m`  
- Adds SSUM structural distance and efficiency per session  
- Tiny engine size: ~14 KB (core + utils)

Then start typing:

`you>`

---

## Commands overview

*(All commands work with or without `:`)*

### General
- `help` → show banner and commands  
- `quit` → exit cleanly  

### Memory
- `history` → show last 10 turns  
- `clear` → erase memory (with confirmation)  

### Verification
- `verify` → short SHA-256 of `memory.json`  
- `verify full` → full SHA-256 digest  

### SSUM insights
- `sd` → structural distance summary  
- `lane` → explanation of `(m, a, s)`  

### Export
- `export` → export full session to Markdown  

---

## Example interaction

```
you> I feel a bit stuck today
[verify] memory_sha256 = f37fbefcb681
aim[m=0.08 a=-0.24 s=0.07]>
Recorded. Reduce this to one controllable step today.
Initial posture recorded relative to the engine’s implicit baseline.
Your structural step cost is D=0.13 with eta=2.09.
(eta>1 means more resistance per classical change).
```

---

What happened internally:

- symbolic state computed  
- structural distance updated (including Turn 1 from baseline)  
- efficiency measured  
- memory appended  
- hash verified  

No guessing.  
No cloud.  
No learning.

---

## Why the engine is intentionally small (~14 KB)

Small size is a **design principle**, not a limitation.

It guarantees:

- full inspectability  
- trust  
- reproducibility  
- zero hidden behavior  
- educational clarity  

SSUM-AIM Mini is meant to be:

**the smallest complete example of an Artificial Intelligence Manifest**.

---

## Safety notice

SSUM-AIM Mini is **reflection-only**.

It must not be used for:

- medical  
- legal  
- financial  
- safety-critical  
- automated decisions  

It is a **mirror**, not an authority.

---

## Licensing

**SSUM-AIM Mini — Open Standard License**

You may:

- use  
- modify  
- fork  
- redistribute  
- use commercially or non-commercially  

No registration.  
No fees.  
No restrictions.

“Provided ‘as is’, without warranty of any kind, express or implied.”

## Reference and Attribution (Optional)

SSUM-AIM Mini — Artificial Intelligence Manifest (AIM), built using  
**Shunyaya Structural Universal Mathematics (SSUM).**

Reference to SSUM or SSUM-AIM Mini is **recommended for conceptual context**  
but **not mandatory**.

---

## Position in the Shunyaya ecosystem

- SSM → symbolic state  
- SSUM → structural movement  
- SSUM-AIM Mini → minimal public AIM kernel  
- Full AIM variants → richer personal AI systems  

SSUM-AIM Mini is the **entry point**:  
small, safe, transparent, and real.

---

## Learn more

For the broader Shunyaya framework, symbolic foundations, and related systems:

- **Shunyaya Master Documentation**  
  https://github.com/OMPSHUNYAYA/Shunyaya-Symbolic-Mathematics-Master-Docs

---

## Final note

SSUM-AIM Mini is **slow, small, and honest by design**.

Its purpose is not to replace AI systems —  
but to prove that **transparent, structural AI is possible**,  
even in **~14 KB of plain Python**.

---

## 🏷 **Topics**

ssum, ssum-aim, artificial-intelligence-manifest, structural-intelligence,  
symbolic-ai, deterministic-ai, manifest-first, reproducible-ai,  
offline-ai, transparent-ai, shunyaya

---

© The Authors of the Shunyaya Framework,  
Shunyaya Structural Universal Mathematics and Shunyaya Symbolic Mathematics


