# ssum_aim_utils.py
import json
import math
import hashlib
import os
from datetime import datetime, timezone

EPS = 1e-12


def sanitize_text(text):
    if not isinstance(text, str):
        return ""
    return text.strip()


def normalize_cmd(text):
    if not isinstance(text, str):
        return ""
    t = text.strip().lower()
    if t.startswith(":"):
        t = t[1:]
    return t


def r6(x):
    return float(f"{float(x):.6f}")


def r4(x):
    return float(f"{float(x):.4f}")


def _clip(x, lo=-0.999999, hi=0.999999):
    if x < lo:
        return lo
    if x > hi:
        return hi
    return x


def _uv(a, s):
    a = _clip(a)
    s = _clip(s)
    return math.atanh(a), math.atanh(s)


def sha256_bytes(b: bytes) -> str:
    h = hashlib.sha256()
    h.update(b)
    return h.hexdigest()


def sha256_file(path: str) -> str:
    with open(path, "rb") as f:
        return sha256_bytes(f.read())


def file_sha256_short(path: str) -> str:
    return sha256_file(path)[:12]


def file_sha256_full(path: str) -> str:
    return sha256_file(path)


def now_utc_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def mem_load(path="memory.json"):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"sessions": []}


def mem_save(mem, path="memory.json"):
    if not isinstance(mem, dict):
        mem = {"sessions": []}
    b = json.dumps(mem, ensure_ascii=False, indent=2, sort_keys=True).encode("utf-8")
    h = sha256_bytes(b)
    mem["last_hash"] = h
    b2 = json.dumps(mem, ensure_ascii=False, indent=2, sort_keys=True).encode("utf-8")
    h2 = sha256_bytes(b2)
    mem["last_hash"] = h2
    with open(path, "wb") as f:
        f.write(b2)
    return h2


def export_md(sessions, out_path="ssum_aim_export.md"):
    lines = []
    lines.append("SSUM-AIM Mini — Export")
    lines.append("")
    for e in sessions:
        lines.append(f"Time: {e.get('ts','')}")
        lines.append(f"m,a,s: {e.get('m','')}, {e.get('a','')}, {e.get('s','')}")
        lines.append(
            f"SD:    D={e.get('D_k','')}  Lc={e.get('L_classical','')}  Ls={e.get('L_struct','')}  eta={e.get('eta','')}"
        )
        lines.append(f"User:  {e.get('user','')}")
        lines.append(f"AIM:   {e.get('ai','')}")
        lines.append("-" * 44)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return out_path


def engine_size_kb(paths=None):
    if paths is None:
        base = os.path.dirname(os.path.abspath(__file__))
        paths = [
            os.path.join(base, "ssum_aim_core.py"),
            os.path.join(base, "ssum_aim_utils.py"),
        ]
    total = 0
    for p in paths:
        try:
            with open(p, "rb") as f:
                total += len(f.read())
        except FileNotFoundError:
            pass
    return float(f"{(total / 1024.0):.2f}")


def clamp01(x):
    if x < 0.0:
        return 0.0
    if x > 1.0:
        return 1.0
    return x


def compute_state_m_a_s(text, turn_idx):
    t = (text or "").strip()
    tl = t.lower()

    letters = sum(ch.isalpha() for ch in tl)
    spaces = sum(ch.isspace() for ch in tl)
    digits = sum(ch.isdigit() for ch in tl)
    punct = sum((not ch.isalnum()) and (not ch.isspace()) for ch in tl)
    length = len(tl)

    w = [w for w in tl.replace("\n", " ").split(" ") if w]
    n_words = len(w)

    neg_words = {
        "stuck", "stress", "stressed", "anxious", "worried", "overwhelmed", "pressure", "panic",
        "fear", "afraid", "tired", "exhausted", "blocked", "confused", "hard", "difficult"
    }
    pos_words = {
        "plan", "calm", "ok", "fine", "good", "clear", "ready", "focus", "focused", "stable",
        "small", "step", "progress", "done", "finish", "solve", "working"
    }

    neg_hits = sum(1 for ww in w if ww.strip(".,!?;:()[]{}\"'") in neg_words)
    pos_hits = sum(1 for ww in w if ww.strip(".,!?;:()[]{}\"'") in pos_words)

    m_raw = 0.0
    if length > 0:
        m_raw = (
            0.35 * clamp01(letters / (length + EPS))
            + 0.20 * clamp01(n_words / 40.0)
            + 0.15 * clamp01(punct / 20.0)
            + 0.10 * clamp01(digits / 10.0)
            + 0.20 * clamp01((length - spaces) / (length + EPS))
        )
    m = r4(clamp01(m_raw))

    if (pos_hits + neg_hits) > 0:
        a_raw = (pos_hits - neg_hits) / float(pos_hits + neg_hits)
    else:
        a_raw = 0.05 if n_words >= 6 else 0.0

    s_raw = 0.0
    if length > 0:
        s_raw = 0.25 * clamp01(punct / 12.0) + 0.25 * clamp01(digits / 8.0)
        if "!" in tl or "??" in tl or "!!!" in tl:
            s_raw += 0.15
        if neg_hits > 0 and pos_hits == 0:
            s_raw += 0.15
        if neg_hits > 0 and pos_hits > 0:
            s_raw += 0.05
        if n_words <= 3:
            s_raw += 0.10

    a = r4(_clip(a_raw, -0.9999, 0.9999))
    s = r4(_clip(s_raw, -0.9999, 0.9999))
    return m, a, s


def compute_sd_metrics(sessions, include_last_turn=False):
    n = len(sessions)
    if n <= 0:
        if include_last_turn:
            return (0.0, 0.0, 0.0, 1.0, 0.0, 0.0)
        return {
            "n": 0,
            "L_classical": 0.0,
            "L_struct": 0.0,
            "eta": 1.0,
            "max_R": 0.0,
            "max_Psi": 0.0,
        }

    L_classical = 0.0
    L_struct = 0.0
    max_R = 0.0
    max_Psi = 0.0

    prev_m = 0.0
    prev_a = 0.0
    prev_s = 0.0
    prev_u, prev_v = _uv(prev_a, prev_s)

    last_D = 0.0

    for e in sessions:
        m = float(e.get("m", 0.0))
        a = float(e.get("a", 0.0))
        s = float(e.get("s", 0.0))
        u, v = _uv(a, s)

        R = math.sqrt(u * u + v * v)
        Psi = 0.5 * (u * u + v * v)
        max_R = max(max_R, R)
        max_Psi = max(max_Psi, Psi)

        dm = m - prev_m
        du = u - prev_u
        dv = v - prev_v

        D = math.sqrt(dm * dm + du * du + dv * dv)
        L_classical += abs(dm)
        L_struct += D
        last_D = D

        prev_m = m
        prev_a = a
        prev_s = s
        prev_u = u
        prev_v = v

    eps = 1e-12
    eta = (L_struct / (L_classical + eps)) if L_classical > eps else 1.0

    if include_last_turn:
        return (r6(last_D), r4(L_classical), r6(L_struct), r6(eta), r6(max_R), r6(max_Psi))

    return {
        "n": n,
        "L_classical": r4(L_classical),
        "L_struct": r6(L_struct),
        "eta": r6(eta),
        "max_R": r6(max_R),
        "max_Psi": r6(max_Psi),
    }


def reply_for_text(text, turn_idx, m, a, s, last_D, eta):
    tl = (text or "").strip().lower()
    has_deadline = ("deadline" in tl) or ("deadlines" in tl)
    has_pressure = ("pressure" in tl) or ("stress" in tl) or ("stressed" in tl) or has_deadline
    has_plan = ("plan" in tl) or ("finish" in tl) or ("smallest" in tl) or ("first" in tl)

    if turn_idx == 1:
        if has_pressure:
            msg = "Recorded. Cost is rising faster than progress. Hold the invariant, cut the optional, and take one small stable step."
        else:
            msg = "Recorded. Initial posture recorded."
    else:
        if has_pressure and has_plan:
            msg = "Recorded. Structural load is elevated. Keep only the essential variable in motion; freeze the rest."
        elif has_pressure:
            msg = "Recorded. Resistance is higher this turn. If pressure is real, shrink scope to one controllable action and stop there."
        elif has_plan:
            msg = "Recorded. Movement is stabilizing. Keep the smallest step, verify once, and do not expand scope."
        else:
            msg = "Recorded. Stable movement. Continue with one bounded action and avoid drift."

    msg += f" D={last_D:.6f} eta={eta:.6f} (eta>1 means more resistance per classical change)."
    return msg
