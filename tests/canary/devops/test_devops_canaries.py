import json, glob, time, subprocess, sys, os, importlib, shutil
import pytest
from tests.kpi_asserts import assert_ttft_fast, write_metric

try:
    runner = importlib.import_module("devops_runner.runtime.executor")
except Exception:
    runner = None

def load_cases():
    cases=[]
    for path in glob.glob("tests/canary/devops/*.jsonl"):
        if path.endswith("repos"): continue
        with open(path,"r",encoding="utf-8-sig") as f:   # BOM-friendly
            for line in f:
                line=line.strip()
                if not line: continue
                o=json.loads(line); o["_src"]=path; cases.append(o)
    return cases

@pytest.mark.parametrize("case", load_cases(), ids=lambda c: c.get("id"))
def test_devops_canary(case, tmp_path):
    t0 = time.time()
    repo = case["repo"]
    workspace = tmp_path / (case.get("workspace") or "workspace/repo")
    workspace.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(repo, workspace)
    ttft_ms = int((time.time()-t0)*1000)

    # DRY mode
    if not case.get("run_patch"):
        elapsed_ms = ttft_ms
        assert_ttft_fast(ttft_ms)
        write_metric({"suite":"DevOps","id":case["id"],"category":case.get("category"),
                      "ttft_ms":ttft_ms,"elapsed_ms":elapsed_ms,"kind":"dry"})
        return

    # RUN mode
    patch_script = case.get("patch_script")
    if patch_script:
        cwd = os.getcwd()
        try:
            os.environ["PATCH_TARGET_DIR"] = str(workspace)
            # <<< მთავარია: BOM-friendly კითხვა პაჩისთვის
            code = compile(open(patch_script,"r",encoding="utf-8-sig").read(), patch_script, "exec")
            exec(code, {})
        finally:
            os.chdir(cwd)

    cwd = os.getcwd(); os.chdir(workspace)
    try:
        r = subprocess.run([sys.executable, "-m", "pytest", "-q"], capture_output=True, text=True, timeout=60)
        if r.returncode != 0:
            print(r.stdout); print(r.stderr, file=sys.stderr)
        assert r.returncode == 0, f"pytest failed: {r.stderr}"
    finally:
        os.chdir(cwd)

    elapsed_ms = int((time.time()-t0)*1000)
    assert_ttft_fast(ttft_ms)
    write_metric({"suite":"DevOps","id":case["id"],"category":case.get("category"),
                  "ttft_ms":ttft_ms,"elapsed_ms":elapsed_ms,"kind":"run"})
