#!/usr/bin/env python

import sys


targ_addr = int(sys.argv[1], 16)
src_file  = sys.argv[2]

s = f"S{targ_addr:04x}"

for val in open(src_file, "rb").read():
    s += f"{val:02x}"

print(s.upper())

