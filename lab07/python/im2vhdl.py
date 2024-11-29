# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import argparse
import sys

import cv2
import numpy as np
import os


def im2vhdl(image_path, output_path=None, mono=False, binlen=8, width=None, height=None, display=False, binary_packing=1):
    _, ext = os.path.splitext(image_path)
    # gifs should be processed in a different manner
    frames = 1
    # if ext == ".gif":
    #     cap = cv2.VideoCapture(image_path)
    #     image = []
    #     while True:
    #         ret, last_image = cap.read()
    #         if ret:
    #             image.append(last_image)
    #             frames += 1
    #         else:
    #             break
    #     cap.release()
    # else:
    image = cv2.imread(image_path)

    # resize if w & h is provided
    if width is not None and height is not None:
        image = cv2.resize(image, (width, height))

    # convert color to mono
    if mono:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # input data type resolve
    if image.dtype.type is np.uint8:
        div = 255
    else:
        div = np.max(image)

    if binlen == 1:
        _, image = cv2.threshold(image, div/2, div, cv2.THRESH_BINARY)

    image = (((2 ** binlen) - 1) * (image.astype(np.float32) / div)).astype(np.uint32)

    if mono:
        width, height = np.shape(image)
        channels = 1
    else:
        width, height, channels = np.shape(image)

    imager = np.reshape(image, (width * height, channels))

    if output_path is None:
        output_path = os.path.splitext(image_path)[0]

    mem_path = os.path.splitext(output_path)[0] + '.coe'
    write_coe_file(mem_path, imager, binlen, binary_packing)
    mem_path = os.path.splitext(output_path)[0] + '.mem'
    write_mem_file(mem_path, imager, binlen, channels, binary_packing)
    if display:
        cv2.namedWindow('result', cv2.WINDOW_NORMAL)
        if binlen == 1:
            cv2.imshow('result', image.astype(np.float))
        else:
            cv2.imshow('result', image.astype(np.float)/(2**binlen))
        cv2.waitKey(0)


def write_coe_file(path, data, binary_length, binary_packing):
    file_mem = open(path, "w")
    if file_mem is None:
        print("Failed to open file" + path)
        return
    formatter = "{0:0" + str(binary_length) + "b}"
    file_mem.write("""memory_initialization_radix=2;
memory_initialization_vector=
""")
    for idx in range(int(len(data[:-1*binary_packing])/binary_packing)):
        for pack in range(binary_packing):
            for c in data[idx*binary_packing + pack]:
                file_mem.write(formatter.format(c))
        file_mem.write(",\n")
    for pack in range(binary_packing):
        for c in data[-1*binary_packing + pack]:
            file_mem.write(formatter.format(c))
    file_mem.write(";\n")
    file_mem.close()


def write_mem_file(path, data, binary_length, channels, binary_packing):
    file_mem = open(path, "w")
    if file_mem is None:
        print("Failed to open file" + path)
        return
    formatter = "{0:0" + str(int(np.ceil(channels * binary_length / 4))) + "X}"
    for idx in range(int(len(data)/binary_packing)):
        val = 0
        for pack in range(binary_packing):
            for channel_idx in range(len(data[idx*binary_packing + pack])):
                val <<= binary_length
                val |= data[idx*binary_packing + pack][channel_idx]
        file_mem.write("@{0:08X} ".format(idx)+formatter.format(val) + "\n")
    file_mem.close()


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('-i',
                        help='Input image path',
                        required=True)
    parser.add_argument('-o',
                        help='Output image path',
                        required=False)
    parser.add_argument('-m', '--mono',
                        help='Monochromatic output',
                        action="store_true")
    parser.add_argument('-b', '--bits',
                        help='Used bits',
                        required=False)
    parser.add_argument('-d', '--display',
                        help="Display converted result",
                        action="store_true")
    parser.add_argument('-x', '--width',
                        help='New image width',
                        required=False)
    parser.add_argument('-y', '--height',
                        help='New image height',
                        required=False)
    parser.add_argument('-p', '--binary_packing',
                        help='Pack output bits by multiples',
                        required=False)
    args = parser.parse_args(argv)

    im2vhdl(args.i, args.o, args.mono, int(args.bits), int(args.width) if args.width else None,
            int(args.height) if args.height else None, args.display,
            int(args.binary_packing) if args.binary_packing else 1)


if __name__ == '__main__':
    main(sys.argv[1:])
