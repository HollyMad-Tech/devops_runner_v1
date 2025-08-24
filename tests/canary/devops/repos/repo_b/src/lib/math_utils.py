import re
def divide(a, b):
    # BUG: silently returns inf on /0
    if b == 0:
        raise ZeroDivisionError("division by zero")
    return a / b

def slugify(s: str):
    # refactor target: keep alnum and dashes, lowercase
    return re.sub(r"[^a-z0-9-]","", s.lower().strip().replace(" ","-"))
