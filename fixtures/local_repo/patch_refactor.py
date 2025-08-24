from pathlib import Path
p = Path("src/app.py")
text = p.read_text(encoding="utf-8")
if "Refactor:" not in text:
    text = '"""Refactor: add simple module docstring."""\n' + text
    p.write_text(text, encoding="utf-8")
print("refactor applied")
