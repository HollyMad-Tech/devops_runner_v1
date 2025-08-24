from pathlib import Path
import sys

p = Path("src/app.py")
text = p.read_text(encoding="utf-8").splitlines()

out = []
in_func = False
replaced = False

for i, line in enumerate(text):
    # Start of the target function
    if line.lstrip().startswith("def buggy_is_even("):
        in_func = True
        replaced = True
        # write canonical function header/body (normalized spacing/indent)
        out.append("def buggy_is_even(x):")
        out.append("    return x % 2 == 0")
        continue

    # If we are inside the function, skip its original body until the next 'def ' at same or lower indent
    if in_func:
        # Next function or module-level def -> end skip and include this line
        if line.lstrip().startswith("def "):
            in_func = False
            out.append(line)
        # else: keep skipping
        continue

    # default: copy line as-is
    out.append(line)

# If function wasn't detected (e.g., name changed), fallback to simple string replace
if not replaced:
    s = "\n".join(out)
    s2 = s.replace("x % 2 == 1", "x % 2 == 0")
    if s2 != s:
        out = s2.splitlines()
        replaced = True

# Write back if changed
final = "\n".join(out) + ("\n" if not out[-1].endswith("\n") else "")
if replaced:
    p.write_text("\n".join(out) + "\n", encoding="utf-8")
    print("patched src/app.py")
    sys.exit(0)
else:
    print("no changes applied", file=sys.stderr)
    sys.exit(1)
