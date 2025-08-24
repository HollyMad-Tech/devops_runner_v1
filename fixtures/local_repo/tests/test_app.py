from src.app import add, buggy_is_even

def test_add():
    assert add(2, 3) == 5

def test_even():
    # should be True for even
    assert buggy_is_even(4) is True
