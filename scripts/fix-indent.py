#!/usr/bin/env python3
import os
import sys


for file_name in sys.argv[1:]:
    out_name = os.path.dirname(file_name) + "/new." + \
        os.path.basename(file_name)
    with open(file_name, "r") as f, open(out_name, "w") as o:
        indent = 0
        for line in f:
            line = line.strip()
            if line.startswith("}") or line.count(")") > line.count("("):
                indent -= 1
            for _ in range(indent):
                o.write("\t")
            o.write(line)
            o.write("\n")
            if line.endswith("{") or line.count("(") > line.count(")"):
                indent += 1
        os.rename(out_name, file_name)
