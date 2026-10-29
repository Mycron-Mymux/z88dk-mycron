#!/usr/bin/env python

import sys
import time


targ_addr = int(sys.argv[1], 16)
src_file  = sys.argv[2]
targ_pts  = None if len(sys.argv) < 4 else sys.argv[3]

s = f"S{targ_addr:04x}"

for val in open(src_file, "rb").read():
    s += f"{val:02x}"
s = s.upper()

print(s)
if targ_pts:
    ts = s + "\n"
    with open(f"/dev/pts/{targ_pts}", 'w') as f:
        while len(ts) > 0:
            blk, ts = ts[:1024], ts[1024:]
            print(f"writing block len {len(blk)} rest {len(ts)}")
            f.write(blk)
            time.sleep(0.1)
            f.flush()

