import os
import os, time

def norm_join(a,b):
    # BUG: naive join breaks on Windows / doubles slashes
    return os.path.join(a,b)

def read_text(path):
    # BUG: encoding unspecified; newline handling brittle
    with open(path, "r", encoding="utf-8", newline=None) as f:
        return f.read()

def long_task(seconds: int):
    # BUG: no timeout/limits
    time.sleep(min(seconds, 1.5))
    return True

def sum_even(nums):
    # BUG: sums odd numbers by mistake
    return sum(n for n in nums if n % 2 == 0)
