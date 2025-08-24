from pathlib import Path
import json, time

def write(bundle_root: str, run_id: str, payload: dict) -> str:
    root = Path(bundle_root) / run_id
    root.mkdir(parents=True, exist_ok=True)
    (root / "results.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")
    report = [
        f"# DevOps Runner — Audit Report (run_id: {run_id})",
        f"- Time: {time.strftime('%Y-%m-%d %H:%M:%S')}",
        "## Keys",
        *[f"- {k}" for k in payload.keys()]
    ]
    (root / "report.md").write_text("\n".join(report), encoding="utf-8")
    return str(root)
