from pathlib import Path
t = Path("tests/test_add_extra.py")
t.write_text("from src.app import add\n\ndef test_add_extra():\n    assert add(10, 5) == 15\n", encoding="utf-8")
print("extra test added")
