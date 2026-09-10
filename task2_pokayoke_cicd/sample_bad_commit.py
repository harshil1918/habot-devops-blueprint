# This file INTENTIONALLY violates the Golden Rules to demonstrate the gate.
# It contains a hardcoded secret AND bad formatting. The pipeline must FAIL.
import os
api_key="sk_live_1234567890abcdefghij"   # hardcoded secret -> Gate 1 and 2 fail
def   bad_format( x ):
    return    x+1                          # bad spacing -> Black/Flake8 fail
