/*

Copyright (C) 2024 Mykolas Bamberg <m.a.bamberg.dev@proton.me>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

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

void main(string[] args) {
    immutable max_iter = 64;

    int height = 20;
    int width = 65;

    uint fg_color;
    uint bg_color;

    double[] bounds;

    ubyte posterization = 0;
    double root = 0;

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
            "a|bounds", "Set visible part of the fractal 'x0,y0,x1,y1'", &bounds_string
        );

        if (help_information.helpWanted) {
            defaultGetoptPrinter(
"Usage:
mandelbrot [OPTIONS]

Examples:
mandelbrot -x 100 -y 30 -f 4040ff -b 080810
mandelbrot -p 15 -r 2
mandelbrot -a -1.5,-0.5,-0.75,0 -x 100 -y 40

Arguments:",
                help_information.options);
            return;
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

    } catch (Exception e) {
        writefln("Error: %s\nMore info with --help", e.msg);
        return;
    }

    /* Draw Image */

    foreach (y; 0..height) {
        foreach (x; 0..width) {
            double a = map_num_range(x, 0, width, bounds[0], bounds[2]);
            double b = map_num_range(y, 0, height, bounds[1], bounds[3]);

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

            double t = (n == max_iter) ? 0 : cast(double)n / max_iter;

            if (root != 0) {
                t = pow(t, (1 / root));
            }

            if (posterization != 0) {
                t = cast(ubyte)(t * posterization) / cast(double)posterization;
            }

            uint color = color_lerp(bg_color, fg_color, t);
            writef("\x1b[48;2;%d;%d;%dm ",
                /* r: */ (color >> 16) & 0xff,
                /* g: */ (color >> 8) & 0xff,
                /* b: */ (color >> 0) & 0xff);
        }
        writeln("\x1b[0m");
    }
}

uint color_lerp(uint col_a, uint col_b, double t) {
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

double map_num_range(double value, double s0, double s1, double t0, double t1) {
    return t0 + (t1 - t0) * ((value - s0) / (s1 - s0));
}
