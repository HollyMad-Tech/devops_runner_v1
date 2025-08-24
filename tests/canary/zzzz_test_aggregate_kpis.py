import json, pathlib
from tests.kpi_asserts import aggregate_latency_asserts

def test_aggregate_kpis():
    path = pathlib.Path("metrics/canary_metrics.jsonl")
    if not path.exists():
        return
    rows = []
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if not line.strip(): continue
        rows.append(json.loads(line))
    samples = []
    for r in rows:
        kind = r.get("kind") or ("dry" if r.get("suite")=="RB" else "run")
        samples.append({"kind": kind, "duration_ms": int(r.get("elapsed_ms",0))})
    aggregate_latency_asserts(samples)
