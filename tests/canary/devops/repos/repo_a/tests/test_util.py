from app import util
import os, tempfile, time

def test_norm_join_cross_platform():
    p = util.norm_join("a","b")
    assert p == os.path.join("a","b")

def test_read_text_utf8():
    with tempfile.NamedTemporaryFile("w", delete=False, encoding="utf-8", newline="\n") as f:
        f.write("გამარჯობა\n")
        temp = f.name
    try:
        txt = util.read_text(temp)
        assert "გამარჯობა" in txt
    finally:
        os.unlink(temp)

def test_long_task_timeout_guard():
    t0 = time.time()
    util.long_task(1)
    assert (time.time()-t0) < 2.0  # we expect internal cap

def test_sum_even():
    assert util.sum_even([1,2,3,4,5,6]) == 12
