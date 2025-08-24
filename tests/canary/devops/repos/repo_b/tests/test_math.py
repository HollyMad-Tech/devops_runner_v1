import pytest
from lib.math_utils import divide, slugify

def test_divide_zero_raises():
    with pytest.raises(ZeroDivisionError):
        divide(1,0)

def test_slugify_refactor():
    assert slugify(" Hello  World ") == "hello--world"
