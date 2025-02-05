#!/usr/bin/env python3

import time
import subprocess
import os
import sys

ZOOM_STRENGTH = 1.1
MIN_SEC_BETWEEN_FRAMES = 0.2

x = -1.5
y = 0

if len(sys.argv) == 3:
    x = float(sys.argv[1])
    y = float(sys.argv[2])

zoom = 2

while True:
    try:
        start = time.process_time()

        print('\033[0;0H')

        terminal_size = os.get_terminal_size()
        ratio = terminal_size.columns / terminal_size.lines / 2

        subprocess.run(['./mandelbrot',
                        '-a', f'{-zoom * ratio + x:.100f},{-zoom + y:.100f},{zoom * ratio + x:.100f},{zoom + y:.100f}',
                        '-x', f'{terminal_size.columns}',
                        '-y', f'{terminal_size.lines * 2 - 2}',
                        '-i', '262144',
                        '-q',
                        '-r', '8'])

        zoom = zoom / ZOOM_STRENGTH

        if zoom / terminal_size.columns + x == x or zoom / terminal_size.lines + y == y:
            print("Reached 64bit floating point precision limit")
            exit()

        end = time.process_time()
        time_diff = end - start
        if time_diff < MIN_SEC_BETWEEN_FRAMES:
            time.sleep(MIN_SEC_BETWEEN_FRAMES - time_diff)

    except KeyboardInterrupt:
        exit()
