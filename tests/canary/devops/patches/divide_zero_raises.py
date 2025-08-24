from pathlib import Path
import os
root = Path(os.environ.get("PATCH_TARGET_DIR", "tests/canary/devops/repos/repo_b"))
p = root / "src/lib/math_utils.py"
s = p.read_text(encoding="utf-8")
s = s.replace('if b == 0:\n        return float("inf")', 'if b == 0:\n        raise ZeroDivisionError("division by zero")')
p.write_text(s, encoding="utf-8")
