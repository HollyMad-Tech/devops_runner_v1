from pathlib import Path
import os
root = Path(os.environ.get("PATCH_TARGET_DIR", "tests/canary/devops/repos/repo_a"))
p = root / "src/app/util.py"
s = p.read_text(encoding="utf-8")
s = s.replace('open(path, "r")', 'open(path, "r", encoding="utf-8", newline=None)')
p.write_text(s, encoding="utf-8")
