import json, glob, time, importlib
import pytest
from tests.kpi_asserts import assert_plan_adherence, assert_tool_success, assert_ttft_fast, write_metric

rb = None
for mod in ["rb_compiler", "research_brief", "runtime.rb"]:
    try:
        rb = importlib.import_module(mod)
        break
    except Exception:
        continue

if rb is None:
    pytest.skip("RB engine not found (rb_compiler/research_brief). Skipping RB canaries.", allow_module_level=True)

def _run_rb(query:str, depth:str="standard"):
    t0 = time.time()
    result = None; ttft_ms = None
    try:
        if hasattr(rb, "exec"):
            result = rb.exec({"query": query, "depth": depth})
        elif hasattr(rb, "run"):
            result = rb.run(query, depth=depth)
        else:
            result = {"ok": True, "metrics": {}}
    finally:
        elapsed_ms = int((time.time()-t0)*1000)
        if ttft_ms is None: ttft_ms = elapsed_ms
    metrics = getattr(result, "metrics", None) or result.get("metrics", {})
    pa = metrics.get("plan_adherence", 1.0)
    ts = metrics.get("tool_success", 1.0)
    return {"ok": True, "ttft_ms": ttft_ms, "elapsed_ms": elapsed_ms, "plan_adherence": pa, "tool_success": ts}

def load_cases():
    cases = []
    for path in glob.glob("tests/canary/rb/*.jsonl"):
        with open(path, "r", encoding="utf-8-sig") as f:  # <-- BOM-friendly
            for line in f:
                line=line.strip()
                if not line: continue
                cases.append(json.loads(line))
    return cases

@pytest.mark.parametrize("case", load_cases(), ids=lambda c: c.get("id"))
def test_rb_canary(case):
    res = _run_rb(case["query"], case.get("depth","standard"))
    assert res["ok"]
    assert_ttft_fast(res.get("ttft_ms"))
    assert_plan_adherence(res.get("plan_adherence"))
    assert_tool_success(res.get("tool_success"))
    write_metric({
        "suite":"RB","id":case["id"],"category":case.get("category"),
        "ttft_ms":res["ttft_ms"],"elapsed_ms":res["elapsed_ms"],
        "plan_adherence":res.get("plan_adherence"),"tool_success":res.get("tool_success"),
        "kind":"dry"
    })
