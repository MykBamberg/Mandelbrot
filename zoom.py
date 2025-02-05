#!/usr/bin/env python3

import time
import subprocess
import os
import sys

ZOOM_STRENGTH = 1.1

x = -1.5
y = 0

if len(sys.argv) == 3:
    x = float(sys.argv[1])
    y = float(sys.argv[2])

zoom = 2

while True:
    try:
        print('\033[0;0H')

        terminal_size = os.get_terminal_size()
        ratio = terminal_size.columns / terminal_size.lines / 2

        subprocess.run(['./mandelbrot',
             '-a', f'{-zoom * ratio + x},{-zoom + y},{zoom * ratio + x},{zoom + y}',
             '-x', f'{terminal_size.columns}',
             '-y', f'{terminal_size.lines * 2 - 2}',
             '-q',
             '-r', '1.7'])

        zoom = zoom / ZOOM_STRENGTH

        time.sleep(0.2)
    except KeyboardInterrupt:
        exit()
