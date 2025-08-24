import os, statistics, json, time, pathlib

DEFAULTS = {
    "PLAN_ADHERENCE": 0.90,
    "TOOL_SUCCESS": 0.95,
    "TTFT_MS": 300,
    "P95_DRY_MS": 2000,
    "P95_RUN_MS": 6000,
}

def _envf(key, cast=float):
    v = os.getenv(f"KPI_{key}")
    return cast(v) if v else DEFAULTS[key] if key in DEFAULTS else None

def assert_plan_adherence(value: float):
    thr = _envf("PLAN_ADHERENCE")
    assert value is None or value >= thr, f"Plan-Adherence {value} < {thr}"

def assert_tool_success(value: float):
    thr = _envf("TOOL_SUCCESS")
    assert value is None or value >= thr, f"Tool-Success {value} < {thr}"

def assert_ttft_fast(ttft_ms: float):
    thr = _envf("TTFT_MS", int)
    assert ttft_ms is None or ttft_ms <= thr, f"TTFT {ttft_ms}ms > {thr}ms"

def aggregate_latency_asserts(samples):
    # samples: [{"kind": "dry"|"run", "duration_ms": int}, ...]
    dry = [s["duration_ms"] for s in samples if s.get("kind")=="dry"]
    run = [s["duration_ms"] for s in samples if s.get("kind")=="run"]
    def p95(v):
        if not v: return 0
        v = sorted(v); idx = max(0, int(round(0.95*(len(v)-1))))
        return v[idx]
    p95_dry = p95(dry)
    p95_run = p95(run)
    thr_dry = _envf("P95_DRY_MS", int)
    thr_run = _envf("P95_RUN_MS", int)
    assert p95_dry <= thr_dry, f"p95(dry) {p95_dry}ms > {thr_dry}ms"
    assert p95_run <= thr_run, f"p95(run+tests) {p95_run}ms > {thr_run}ms"

def write_metric(row: dict, path="metrics/canary_metrics.jsonl"):
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")
