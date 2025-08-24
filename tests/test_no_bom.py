import pathlib

ALLOW = {".py", ".toml", ".ini", ".cfg", ".txt"}

def test_no_utf8_bom():
    bad = []
    for p in pathlib.Path(".").rglob("*"):
        if p.is_file() and p.suffix.lower() in ALLOW:
            if b"\xef\xbb\xbf" in p.read_bytes():
                bad.append(str(p))
    assert not bad, "UTF-8 BOM found in: " + ", ".join(bad)