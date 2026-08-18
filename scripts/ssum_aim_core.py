# ssum_aim_core.py
from ssum_aim_utils import (
    sanitize_text,
    normalize_cmd,
    mem_load,
    mem_save,
    file_sha256_short,
    file_sha256_full,
    now_utc_iso,
    compute_state_m_a_s,
    compute_sd_metrics,
    reply_for_text,
    export_md,
    engine_size_kb,
)


def banner_text():
    kb = engine_size_kb()
    return (
        "SSUM-AIM Mini\n"
        "----------------------------------------------------\n"
        "- Fully local • Offline • Deterministic • Stdlib-only\n"
        "- Manifest-first behavior (no hidden training, no cloud)\n"
        "- Guarantees classical collapse: phi((m,a,s)) = m\n"
        "- Adds SSUM structural distance and efficiency per session\n"
        f"- Tiny engine size: ~{kb:.2f} KB (core + utils)\n"
        "\n"
        "Commands:\n"
        "  :help\n"
        "  :history           show last 10 turns\n"
        "  :verify            show short SHA256 of memory.json\n"
        "  :verify full       show full SHA256 of memory.json\n"
        "  :sd                show SSUM distance summary (L_classical, L_struct, eta)\n"
        "  :lane              show lane tutorial (m,a,s + collapse rule)\n"
        "  :export            export full history to ssum_aim_export.md\n"
        "  :clear             erase memory (with confirmation)\n"
        "  :quit              exit\n"
    )


def print_lane():
    print("[lane] (m,a,s) + SSUM distance")
    print("  state: (m,a,s)")
    print("  collapse: phi((m,a,s)) = m")
    print("  u = atanh(a)")
    print("  v = atanh(s)")
    print("  D = sqrt((dm)^2 + (du)^2 + (dv)^2)")
    print("  eta = L_struct / (L_classical + eps)")
    print("  Note: Turn 1 is measured from an implicit baseline (m,a,s) = (0,0,0).")


def print_sd(mem):
    sessions = mem.get("sessions", [])
    sd = compute_sd_metrics(sessions, include_last_turn=False)
    print("[sd] SSUM distance summary")
    print(f"  turns:       {sd.get('n', 0)}")
    print(f"  L_classical: {sd.get('L_classical', 0.0)}")
    print(f"  L_struct:    {sd.get('L_struct', 0.0)}")
    print(f"  eta:         {sd.get('eta', 1.0)}")
    print(f"  max_R:       {sd.get('max_R', 0.0)}")
    print(f"  max_Psi:     {sd.get('max_Psi', 0.0)}")


def print_history(mem, k=10):
    sessions = mem.get("sessions", [])
    if not sessions:
        print("[history] (empty)")
        return
    tail = sessions[-k:]
    print(f"[history] Showing up to last {len(tail)} entries:")
    for e in tail:
        print(f"Time:  {e.get('ts', '')}")
        print(f"m,a,s: {e.get('m','NA')}, {e.get('a','NA')}, {e.get('s','NA')}")
        print(
            f"SD:    D={e.get('D_k','NA')}  Lc={e.get('L_classical', 'NA')}  "
            f"Ls={e.get('L_struct','NA')}  eta={e.get('eta','NA')}"
        )
        print(f"User:  {e.get('user','')}")
        print(f"AIM:   {e.get('ai','')}")
        print("-" * 44)


def main():
    mem = mem_load("memory.json")
    print(banner_text())

    while True:
        try:
            raw = input("you> ")
        except (EOFError, KeyboardInterrupt):
            print("\nExiting SSUM-AIM Mini. Goodbye.")
            break

        raw = sanitize_text(raw)
        cmd = normalize_cmd(raw)

        if cmd in ("quit", "exit"):
            print("Exiting SSUM-AIM Mini. Goodbye.")
            break

        if cmd == "help":
            print(banner_text())
            continue

        if cmd == "lane":
            print_lane()
            continue

        if cmd == "sd":
            print_sd(mem)
            continue

        if cmd == "history":
            print_history(mem, k=10)
            continue

        if cmd == "verify":
            h = file_sha256_short("memory.json") if mem.get("sessions") else "none"
            print(f"[verify] memory_sha256 (short) = {h}")
            continue

        if cmd == "verify full":
            h = file_sha256_full("memory.json") if mem.get("sessions") else "none"
            print(f"[verify] full SHA256 (memory.json) = {h}")
            continue

        if cmd == "export":
            out_path = export_md(mem.get("sessions", []), out_path="ssum_aim_export.md")
            print(f"[export] history exported to {out_path}")
            continue

        if cmd == "clear":
            print("This will erase local mini memory. Type 'yes' to confirm: ", end="")
            confirm = sanitize_text(input()).lower()
            if confirm == "yes":
                mem = {"sessions": []}
                mem_save(mem, "memory.json")
                print("[clear] Mini memory erased.")
            else:
                print("[clear] canceled")
            continue

        if not raw:
            continue

        turn_idx = len(mem.get("sessions", [])) + 1
        m, a, s = compute_state_m_a_s(raw, turn_idx)

        tmp_sessions = list(mem.get("sessions", []))
        tmp_sessions.append({"m": m, "a": a, "s": s})

        last_D, Lc, Ls, eta, max_R, max_Psi = compute_sd_metrics(tmp_sessions, include_last_turn=True)

        ai = reply_for_text(raw, turn_idx, m, a, s, last_D, eta)

        entry = {
            "ts": now_utc_iso(),
            "turn": turn_idx,
            "user": raw,
            "ai": ai,
            "m": m,
            "a": a,
            "s": s,
            "D_k": last_D,
            "L_classical": Lc,
            "L_struct": Ls,
            "eta": eta,
            "max_R": max_R,
            "max_Psi": max_Psi,
        }

        mem.setdefault("sessions", []).append(entry)
        h = mem_save(mem, "memory.json")

        print(f"[verify] memory_sha256 = {h[:12]}")
        print(f"aim[m={m:.4f} a={a:.4f} s={s:.4f}]>")
        print(ai)


if __name__ == "__main__":
    main()
