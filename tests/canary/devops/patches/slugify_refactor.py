from pathlib import Path
import os, re
root = Path(os.environ.get("PATCH_TARGET_DIR", "tests/canary/devops/repos/repo_b"))
p = root / "src/lib/math_utils.py"
s = p.read_text(encoding="utf-8")
if "import re" not in s:
    s = "import re\n" + s
s = s.replace('return s.strip().replace(" ","-")',
              'return re.sub(r"[^a-z0-9-]","", s.lower().strip().replace(" ","-"))')
p.write_text(s, encoding="utf-8")
