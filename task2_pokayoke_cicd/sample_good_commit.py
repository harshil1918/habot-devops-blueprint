"""Reference file that passes every gate: no secrets, clean formatting."""
import os


def add_one(value: int) -> int:
    """Return value incremented by one."""
    return value + 1


API_KEY = os.environ["DOWNSTREAM_API_KEY"]  # read from environment, never hardcoded
