# Windows CMD Workflow — SSUM-AIM Mini  
## Test and Run Guide

This guide shows how to:

- launch the SSUM-AIM Mini console
- run a complete interactive session
- inspect structural state (`m, a, s`)
- view SSUM structural distance
- verify memory integrity (SHA-256)
- export a transcript
- clear memory safely
- quit cleanly

All outputs below are **representative**.  
Your exact SHA-256 values and timestamps will differ.

---

## 1. Open Command Prompt

Press:

Win + R → `cmd` → Enter

---

## 2. Navigate to Your SSUM-AIM Mini Folder

Example:

`cd C:\Users\YourName\Desktop\SSUM_AIM_MINI`

Use any folder location where you placed the scripts.

Your folder should contain:

- `scripts/ssum_aim_core.py`
- `scripts/ssum_aim_utils.py`

On first run, the console will create:

- `memory.json`

---

## 3. Launch SSUM-AIM Mini

Run:

`python scripts/ssum_aim_core.py`

You will see:

SSUM-AIM (Mini) — Artificial Intelligence Manifest  
Built using Shunyaya Structural Universal Mathematics (SSUM)  
------------------------------------------------------------
- Fully local • Offline • Deterministic • Stdlib-only
- Manifest-first behavior (no hidden training, no cloud)
- Guarantees classical collapse: `phi((m,a,s)) = m`
- Adds SSUM structural distance and efficiency per session
- Tiny engine size: ~14 KB (core + utils)

Commands:

- `:help`
- `:history`           show last 10 turns
- `:verify`            show short SHA256 of `memory.json`
- `:verify full`       show full SHA256 of `memory.json`
- `:sd`                show SSUM distance summary (`L_classical`, `L_struct`, `eta`)
- `:lane`              show lane tutorial (`m,a,s` + collapse rule)
- `:export`            export full history to `ssum_aim_export.md`
- `:clear`             erase memory (with confirmation)
- `:quit`              exit

---

## 4. Start From a Clean State (Recommended)

Before recording or testing, clear memory:

you> `:clear`  
This will erase local mini memory. Type 'yes' to confirm: yes  
[clear] Mini memory erased.

This establishes a fresh deterministic baseline.

---

## 5. Example Interactive Session (Full Workflow)

you> I feel a bit stuck today  
[verify] memory_sha256 = 9fcd15bfa4a8  
aim[m=0.0923 a=-0.1466 s=0.0352]>  
Recorded. Reduce this to one controllable step and one measurable outcome.  
Initial posture recorded relative to the engine’s implicit baseline.  
D=0.214781  eta=2.327914  
(eta>1 means more resistance per classical change).

you> I have a plan but deadlines are making it stressful  
[verify] memory_sha256 = aa4f1a5dd340  
aim[m=0.1962 a=0.0461 s=0.0217]>  
Recorded. Resistance is higher this turn.  
If pressure is real, shrink the scope to one controllable action and stop there.  
Your structural step cost is D=0.220306 with eta=2.120370  
(eta>1 means more resistance per classical change).

you> I will finish the smallest test first and ignore the rest today  
[verify] memory_sha256 = 6b252d9ad033  
aim[m=0.2423 a=0.1803 s=-0.0129]>  
Recorded. Cost is rising faster than progress.  
Hold the invariant, cut the optional, and take one small stable step.  
Your structural step cost is D=0.147859 with eta=2.454434  
(eta>1 means more resistance per classical change).

---

## 6. View SSUM Structural Distance

you> `:sd`

[sd] SSUM distance summary  
turns:       3  
L_classical: 0.15  
L_struct:    0.368165  
eta:         2.454434  
max_R:       0.182749  
max_Psi:     0.016699

### Interpretation

- Classical progress occurred
- Structural effort was significantly higher
- Efficiency `eta > 1` indicates resistance beyond classical change

---

## 7. View the Lane Tutorial

you> `:lane`

You will see a short explanation of:

- the structural state (`m, a, s`)
- the collapse rule `phi((m,a,s)) = m`
- how alignment (`a`) and suppression (`s`) behave
- how structural distance is computed

---

## 8. View Recent History

you> `:history`

Example:

[history] Showing up to last 10 entries:

Time:  2026-01-10T09:41:02Z  
m,a,s: 0.2423, 0.1803, -0.0129  
SD:    D=0.147859  Lc=0.15  Ls=0.368165  eta=2.454434  
User:  I will finish the smallest test first and ignore the rest today  
AIM:   Recorded. Cost is rising faster than progress...  
(history continues)
...

---

## 9. Verify Memory Integrity

Short SHA-256:

you> `:verify`  
[verify] memory_sha256 (short) = 6b252d9ad033

Full SHA-256:

you> `:verify full`  
[verify] full SHA256 (memory.json) = e434fe54f...

This confirms tamper-evident local memory.

---

## 10. Export the Session Transcript

you> `:export`  
[export] history exported to `ssum_aim_export.md`

A Markdown transcript appears in the same folder.

---

## 11. Clear Memory

you> `:clear`  
This will erase local mini memory. Type 'yes' to confirm: yes  
[clear] Mini memory erased.

---

## 12. Quit Safely

you> `:quit`  
Exiting SSUM-AIM (Mini). Goodbye.

The console exits cleanly without modifying memory.

---

## End of Test and Run Guide

This guide demonstrates that SSUM-AIM Mini is:

- deterministic
- fully offline
- manifest-first
- structurally observable
- cryptographically verifiable

All of this is delivered in ~14 KB of plain Python, with:

- no hidden training
- no network access
- no opaque behavior

Each turn preserves classical meaning while revealing structural cost, resistance, and efficiency from the very first interaction — the core promise of an **Artificial Intelligence Manifest (AIM)** built using **Shunyaya Structural Universal Mathematics (SSUM)**.
