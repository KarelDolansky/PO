# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import argparse
import sys
import cv2
import numpy as np
import os


def raw2vhdl(input_path, output_path=None):

    if output_path is None:
        mem_path = os.path.splitext(input_path)[0] + '.mem'
    else:
        mem_path = output_path
    write_mem_file(input_path, mem_path)
    coe_path = os.path.splitext(mem_path)[0] + '.coe'
    write_coe_file(input_path, coe_path)


def write_mem_file(ipath, opath):
    with open(ipath, "rb") as f_i:
        with open(opath, "w") as f_o:
            idx = 0
            byte = f_i.read(1)
            while byte:
                f_o.write("@{0:08X} ".format(idx) + byte.hex() + "\n")
                idx += 1
                byte = f_i.read(1)


def write_coe_file(ipath, opath):
    with open(ipath, "rb") as f_i:
        with open(opath, "w") as f_o:
            f_o.write("""memory_initialization_radix=16;
            memory_initialization_vector=
            """)
            byte = f_i.read(1)
            while byte:
                f_o.write(byte.hex())
                byte = f_i.read(1)
                if byte:
                    f_o.write(",\n")
                else:
                    f_o.write(";\n")


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('-i',
                        help='Input audio path',
                        required=True)
    parser.add_argument('-o',
                        help='Output mem/coe path',
                        required=False)
    args = parser.parse_args(argv)

    raw2vhdl(args.i, args.o)


if __name__ == '__main__':
    main(sys.argv[1:])
