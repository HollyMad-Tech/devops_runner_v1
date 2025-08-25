import os, json, uuid, zipfile, re, logging
from datetime import datetime
from pathlib import Path
from fastapi import FastAPI, Request
from logging.handlers import RotatingFileHandler

def _to_bytes(s: str) -> int:
    if not s: return 10 * 1024 * 1024
    m = re.match(r"(?i)^\s*(\d+(?:\.\d+)?)\s*([KMG]?B)?\s*$", s)
    if not m: return 10 * 1024 * 1024
    n = float(m.group(1)); unit = (m.group(2) or "B").upper()
    mul = {"B":1,"KB":1024,"MB":1024**2,"GB":1024**3}.get(unit,1)
    return int(n * mul)

# --- ENV & paths ---
PORT         = int(os.getenv("PORT", "8765"))
WORKSPACE    = Path(os.getenv("WORKSPACE", "./workspace")).resolve()
LOG_DIR      = Path(os.getenv("LOG_DIR", "./logs")).resolve()
METRICS_JSONL= Path(os.getenv("METRICS_JSONL", "./workspace/metrics/metrics.jsonl")).resolve()
EXPORTS_DIR  = Path(os.getenv("EXPORTS_DIR", "./workspace/exports")).resolve()
AUDIT_DIR    = Path(os.getenv("AUDIT_DIR", "./workspace/audit")).resolve()

for p in [WORKSPACE, LOG_DIR, METRICS_JSONL.parent, EXPORTS_DIR, AUDIT_DIR, WORKSPACE / "commits"]:
    p.mkdir(parents=True, exist_ok=True)

# --- logging (rotating file) ---
_log_path = LOG_DIR / os.getenv("LOG_FILE","app.log")
_handler = RotatingFileHandler(
    _log_path,
    maxBytes=_to_bytes(os.getenv("LOG_MAX","10MB")),
    backupCount=int(os.getenv("LOG_BACKUPS","5")),
)
logging.basicConfig(level=logging.INFO, handlers=[_handler])
logger = logging.getLogger("sena")

app = FastAPI(title="SENA Mock v0.2.0")

@app.middleware("http")
async def _log_requests(request, call_next):
    logger.info("REQ %s %s", request.method, request.url.path)
    resp = await call_next(request)
    logger.info("RES %s %s %s", request.method, request.url.path, resp.status_code)
    return resp

def _now(): return datetime.utcnow().isoformat() + "Z"

@app.get("/health")
def health():
    return {"ok": True, "build_mode": os.getenv("BUILD_MODE","PILOT")}

@app.get("/debug/timings")
def timings():
    return {"ttft_ms": 120, "p95_ms": {"dry": 1300, "run_tests": 4800}}

@app.post("/plan")
async def plan(request: Request):
    try:
        body = await request.json()
    except Exception:
        body = {}
    wid = f"plan_{uuid.uuid4().hex[:8]}"
    wf  = (body or {}).get("workflow","unknown")
    if wf == "research_brief":
        outline = ["Background","Current","Options","Risks","Recommendation"]
    elif wf == "devops_patch":
        outline = ["Ticket","Dry-run","Run","Tests","Commit","Summary"]
    else:
        outline = ["Steps"]
    if not METRICS_JSONL.exists():
        METRICS_JSONL.write_text("", encoding="utf-8")
    with METRICS_JSONL.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"ts":_now(),"event":"plan","workflow":wf})+"\n")
    return {
        "id": wid,
        "workflow": wf,
        "outline": outline,
        "adherence_target": 1.0,
        "steps": [{"tool":"mock.step","args":{}}]
    }

@app.post("/exec")
async def exec_(request: Request):
    try:
        body = await request.json()
    except Exception:
        body = {}
    kpis = {
        "ttft_s": 0.12,
        "p95_s": {"dry": 1.3, "run_tests": 4.8},
        "plan_adherence": 0.95,
        "tool_success": 0.98,
        "rb_hard_halluc": 0.0
    }
    run_id = f"run_{uuid.uuid4().hex[:8]}"
    run_dir = AUDIT_DIR / f"{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{run_id}"
    run_dir.mkdir(parents=True, exist_ok=True)

    md_path   = EXPORTS_DIR / f"{run_id}.md"
    html_path = EXPORTS_DIR / f"{run_id}.html"
    pdf_path  = EXPORTS_DIR / f"{run_id}.pdf"
    md_path.write_text("# Research Brief\n\n## Background\n...\n## Current\n...\n## Options\n...\n## Risks\n...\n## Recommendation\n...", encoding="utf-8")
    html_path.write_text("<html><body><h1>Research Brief</h1><h2>Background</h2>...</body></html>", encoding="utf-8")
    pdf_path.write_bytes(b"%PDF-1.4\n% Mock PDF\n1 0 obj <<>> endobj\ntrailer <<>>\n%%EOF\n")

    commit_id = f"{uuid.uuid4().hex[:7]}"
    (WORKSPACE / "commits").mkdir(parents=True, exist_ok=True)
    (WORKSPACE / "commits" / f"{commit_id}.txt").write_text("Problem: ...\n\nApproach: ...\n\nTests: ...\n\nRisks: ...\n", encoding="utf-8")

    plan_json = run_dir / "plan.json"
    run_json  = run_dir / "run.json"
    plan_json.write_text(json.dumps({"id":"mock_plan","ts":_now()}), encoding="utf-8")
    run_json.write_text(json.dumps({"id":run_id,"kpis":kpis,"exports":{"md":str(md_path),"html":str(html_path),"pdf":str(pdf_path)}}), encoding="utf-8")
    audit_zip = run_dir / "Audit.zip"
    with zipfile.ZipFile(audit_zip, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(plan_json, arcname="plan.json")
        z.write(run_json,  arcname="run.json")
        z.write(md_path,   arcname=f"exports/{md_path.name}")
        z.write(html_path, arcname=f"exports/{html_path.name}")
        z.write(pdf_path,  arcname=f"exports/{pdf_path.name}")

    with METRICS_JSONL.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"ts":_now(),"event":"exec","run_id":run_id})+"\n")

    return {
        "run_id": run_id,
        "status": "ok",
        "artifacts": {
            "exports": {"pdf": str(pdf_path), "md": str(md_path), "html": str(html_path)},
            "audit_zip": str(audit_zip),
            "commit_id": commit_id,
            "kpis": kpis
        }
    }