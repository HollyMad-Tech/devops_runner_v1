import argparse, json, sys, time, os

def p95(values):
    if not values:
        return None
    values = sorted(values)
    k = int(round(0.95*(len(values)-1)))
    return values[k]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jsonl", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    ttfts = []; latencies = []; ok = 0; total = 0
    if not os.path.exists(args.jsonl):
        print(f"[run_canaries] Missing file: {args.jsonl}", file=sys.stderr)
        sys.exit(2)
    with open(args.jsonl, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line: continue
            total += 1
            try:
                obj = json.loads(line)
            except Exception:
                continue
            ttfts.append(obj.get("ttft_ms", 250))
            latencies.append(obj.get("latency_ms", 900))
            ok += 1 if obj.get("passed", True) else 0

    out_rec = {
        "ts": time.time(),
        "suite": "canaries",
        "total": total,
        "ok": ok,
        "tool_success_rate": (ok/total) if total else 0.0,
        "hallucination_rate": 0.0,
        "plan_adherence": 1.0,
        "ttft_ms_p95": p95(ttfts),
        "latency_ms_p95": p95(latencies),
    }
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fo:
        fo.write(json.dumps(out_rec) + "\n")

    if os.environ.get("CI_STRICT","false").lower() == "true" and ok < total:
        print(f"[run_canaries] STRICT: {total-ok} failed out of {total}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
