import argparse, json, os

def load_jsonl(path):
    out=[]
    if not os.path.exists(path): return out
    with open(path,"r",encoding="utf-8") as fh:
        for line in fh:
            line=line.strip()
            if not line: continue
            try: out.append(json.loads(line))
            except Exception: pass
    return out

def p95(vals):
    if not vals: return None
    vals=sorted(vals)
    k=int(round(0.95*(len(vals)-1)))
    return vals[k]

def fmt(v):
    if v is None: return "N/A"
    if isinstance(v, float): return f"{v:.3f}"
    return str(v)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--metrics-dir", required=True)
    ap.add_argument("--out", required=True)
    args=ap.parse_args()

    os.makedirs(args.metrics_dir, exist_ok=True)
    e2e = load_jsonl(os.path.join(args.metrics_dir,"e2e_smoke_metrics.jsonl"))
    canary_path = os.path.join(args.metrics_dir,"canary_metrics.jsonl")
    canary = load_jsonl(canary_path)
    if not canary and os.path.exists(canary_path):
        try:
            with open(canary_path,"r",encoding="utf-8") as fh:
                line=fh.read().strip()
                if line: canary=[json.loads(line)]
        except Exception: pass

    plan=[]; tool=[]; hallu=[]; ttft=[]; lat=[]
    for rec in e2e+canary:
        if "plan_adherence" in rec: plan.append(rec["plan_adherence"])
        if "tool_success_rate" in rec: tool.append(rec["tool_success_rate"])
        if "hallucination_rate" in rec: hallu.append(rec["hallucination_rate"])
        if "ttft_ms" in rec: ttft.append(rec["ttft_ms"])
        if "ttft_ms_p95" in rec: ttft.append(rec["ttft_ms_p95"])
        if "latency_ms" in rec: lat.append(rec["latency_ms"])
        if "latency_ms_p95" in rec: lat.append(rec["latency_ms_p95"])

    summary = {
        "Plan-Adherence(avg)": (sum(plan)/len(plan)) if plan else None,
        "Tool-Success(avg)": (sum(tool)/len(tool)) if tool else None,
        "Hallucination(avg)": (sum(hallu)/len(hallu)) if hallu else None,
        "TTFT p95 (ms)": p95(ttft),
        "Latency p95 (ms)": p95(lat),
    }

    lines = [
        "KPI Summary","-----------",
        f"Plan-Adherence: {fmt(summary['Plan-Adherence(avg)'])}",
        f"Tool-Success  : {fmt(summary['Tool-Success(avg)'])}",
        f"Hallucination : {fmt(summary['Hallucination(avg)'])}",
        f"TTFT p95 (ms) : {fmt(summary['TTFT p95 (ms)'])}",
        f"p95 latency(ms): {fmt(summary['Latency p95 (ms)'])}",
        "",
        "(Populate metrics via your smokes/canaries to make these numbers meaningful.)"
    ]
    with open(args.out,"w",encoding="utf-8") as fo:
        fo.write("\n".join(lines))
    print("\n".join(lines))

if __name__=="__main__":
    main()
