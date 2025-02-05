/*
Copyright (C) 2024  Mykolas Bamberg <m.a.bamberg.dev@proton.me>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see
<https://www.gnu.org/licenses/>.
*/

import std.stdio;
import std.format;
import std.range;
import std.algorithm;
import std.math;
import std.getopt;
import std.conv;
import std.string;
import std.regex;
import std.parallelism;

void main(string[] args) {
    immutable work_unit_size = 256;

    uint max_iter = 64;

    int height = 40;
    int width = 65;

    uint fg_color;
    uint bg_color;

    double[] bounds;

    ubyte posterization = 0;
    double root = 0;

    bool hash_colors = false;
    bool ascii_only = false;

    string bmp_output = "";

    /* Parse Arguments */

    try {
        string fg_string = "8acaf6";
        string bg_string = "292831";
        string bounds_string = "-2,-1,1,1";

        auto help_information = getopt(
            args,
            "x|width", "Width of output", &width,
            "y|height", "Height of output", &height,
            "f|foreground", "Foreground color in hex", &fg_string,
            "b|background", "Background color in hex", &bg_string,
            "p|posterization", "Set posterization level", &posterization,
            "r|root", "Set the nth root of the brightness level", &root,
            "a|bounds", "Set visible part of the fractal 'x0,y0,x1,y1'", &bounds_string,
            "t|ascii", "Only use ASCII characters", &ascii_only,
            "q|hash", "Hash brightness values, creates a strong visual variation between color bands", &hash_colors,
            "i|iterations", "Maximum number of iterations", &max_iter,
            "o|output", "Output as Bitmap image", &bmp_output
        );

        if (help_information.helpWanted) {
            defaultGetoptPrinter(
"Usage:
mandelbrot [OPTIONS]

Examples:
mandelbrot -x 100 -y 60 -f 4040ff -b 080810
mandelbrot -p 15 -r 2
mandelbrot -a -1.5,-0.5,-0.75,0 -x 100 -y 80

Arguments:",
                help_information.options);
            return;
        }

        if (width <= 0) {
            width = max(-width, 1);
        }

        if (height <= 0) {
            height = max(-height, 1);
        }

        if (!fg_string.match(r"^[0-9A-Fa-f]{6}$")
            || !bg_string.match(r"^[0-9A-Fa-f]{6}$")) {
            throw new Exception("Colors must be 6-digit hex values");
        }

        fg_color = to!uint(fg_string, 16);
        bg_color = to!uint(bg_string, 16);

        immutable bounds_error = "Bounds must be a comma separated list of four decimal numbers";

        try {
            bounds = map!(to!double)(bounds_string.split(",")).array;
        } catch (Exception) {
            throw new Exception(bounds_error);
        }

        if (bounds.length != 4) {
            throw new Exception(bounds_error);
        }

        if (bmp_output == "-") {
            bmp_output = "/dev/stdout";
        }
    } catch (Exception e) {
        writefln("Error: %s\nMore info with --help", e.msg);
        return;
    }

    /* Increase height to nearest even number */
    if (bmp_output == "") {
        height += height % 2;
    }

    /* Calculate colors */
    auto colors = new uint[height * width];

    foreach (i, ref color; taskPool.parallel(colors, work_unit_size)) {
        ulong y = i / width;
        ulong x = i % width;
        double a = map_num_range(x, 0, width - 1, bounds[0], bounds[2]);
        double b = map_num_range(y, 0, height - 1, bounds[1], bounds[3]);
        color = intensity_to_color(
            mandelbrot(a, b, max_iter),
            root, posterization, hash_colors, fg_color, bg_color);
    }

    /* Output Bitmap file */
    if (bmp_output != "") {
        /* Size of full header / offset of image data */
        immutable offset = 54;
        uint file_size = offset + cast(uint)(uint.sizeof * colors.length);
        ubyte[] header = [
            /* BMP header */
            'B', 'M',
            file_size & 0xff, file_size >> 8 & 0xff, file_size >> 16 & 0xff, file_size >> 24 & 0xff,
            0, 0,
            0, 0,
            offset & 0xff, offset >> 8 & 0xff, offset >> 16 & 0xff, offset >> 24 & 0xff,
            /* BITMAPINFOHEADER */
            40, 0, 0, 0,
            width & 0xff, width >> 8 & 0xff, width >> 16 & 0xff, width >> 24 & 0xff,
            height & 0xff, height >> 8 & 0xff, height >> 16 & 0xff, height >> 24 & 0xff,
            1, 0,
            32, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0b11000100, 0b00001110, 0, 0,
            0b11000100, 0b00001110, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0
        ];

        try {
            auto f = File(bmp_output, "wb");
            f.rawWrite(header);
            f.rawWrite(colors);
            f.close();
        } catch (Exception e) {
            writefln("Error: %s", e.msg);
        }

        return;
    }

    /* Display colors */
    foreach (y; 0..height / 2) {
        foreach (x; 0..width) {
            uint f_color = colors[2 * y * width + x];
            uint b_color = colors[(2 * y + 1) * width + x ];

            writef("\x1b[48;2;%d;%d;%dm\x1b[38;2;%d;%d;%dm",
                /* background r: */ (b_color >> 16) & 0xff,
                /* background g: */ (b_color >> 8) & 0xff,
                /* background b: */ (b_color >> 0) & 0xff,
                /* foreground r: */ (f_color >> 16) & 0xff,
                /* foreground g: */ (f_color >> 8) & 0xff,
                /* foreground b: */ (f_color >> 0) & 0xff);

            write(ascii_only ? " " : "▀");
        }
        writeln("\x1b[0m");
    }
}

@nogc pure nothrow double mandelbrot(double a, double b, uint max_iter) {
    double ca = a;
    double cb = b;

    int n;
    for (n = 0; n < max_iter; n++) {
        double aa = a * a - b * b;
        double bb = 2 * a * b;
        a = aa + ca;
        b = bb + cb;
        if (a * a + b * b > 4) {
            break;
        }
    }

    return (n == max_iter) ? 0 : cast(double)n / max_iter;
}

@nogc pure nothrow uint intensity_to_color(double t, double root, double posterization, bool hash_colors, uint fg, uint bg) {
    if (root != 0) {
        t = pow(t, (1 / root));
    }

    if (posterization != 0) {
        t = cast(ubyte)(t * posterization) / cast(double)posterization;
    }

    return hash_colors ?
        color_hash(bg, fg, t) :
        color_lerp(bg, fg, t);
}

@nogc pure nothrow uint color_lerp(uint col_a, uint col_b, double t) {
    ubyte r_a = (col_a >> 16) & 0xff;
    ubyte g_a = (col_a >> 8) & 0xff;
    ubyte b_a = (col_a >> 0) & 0xff;
    ubyte r_b = (col_b >> 16) & 0xff;
    ubyte g_b = (col_b >> 8) & 0xff;
    ubyte b_b = (col_b >> 0) & 0xff;
    ubyte r_ret = cast(ubyte)(r_a * (1 - t) + r_b * t);
    ubyte g_ret = cast(ubyte)(g_a * (1 - t) + g_b * t);
    ubyte b_ret = cast(ubyte)(b_a * (1 - t) + b_b * t);
    return (r_ret << 16) + (g_ret << 8) + b_ret;
}

@nogc pure nothrow double map_num_range(double value, double s0, double s1, double t0, double t1) {
    return t0 + (t1 - t0) * ((value - s0) / (s1 - s0));
}

@nogc pure nothrow uint color_hash(uint bg, uint fg, double t) {
    uint val = cast(uint)(t * 1000);
    val = ((val >> 16) ^ val) * 0x45d9f3b >> 16;
    return color_lerp(bg, fg, (val % 256) / 256.0 * t);
}
