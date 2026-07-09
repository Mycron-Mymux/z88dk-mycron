#!/usr/bin/env python

import sys


targ_addr = int(sys.argv[1], 16)
src_file  = sys.argv[2]
targ_pts  = None if len(sys.argv) < 4 else sys.argv[3]

s = f"S{targ_addr:04x}"

for val in open(src_file, "rb").read():
    s += f"{val:02x}"
s = s.upper()

print(s)
if targ_pts:
    with open(f"/dev/pts/{targ_pts}", 'w') as f:
        f.write(s + "\n")

