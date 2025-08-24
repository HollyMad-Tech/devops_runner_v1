from pathlib import Path
import os
root = Path(os.environ.get("PATCH_TARGET_DIR", "tests/canary/devops/repos/repo_a"))
p = root / "src/app/util.py"
s = p.read_text(encoding="utf-8")
s = s.replace('return a + "/" + b', 'return os.path.join(a,b)')
# top-level import os already exists in util.py, but keep safe:
if "import os" not in s.splitlines()[0:3]:
    s = "import os\n" + s
p.write_text(s, encoding="utf-8")
