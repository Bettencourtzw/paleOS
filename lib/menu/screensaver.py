#!/usr/bin/env python3
# Screensaver: the Arch logo appears, holds, and disappears with a random clean effect
# each cycle (dissolve, wipe, rain, center-out, typewriter). Any key / mouse = exit.
import curses, math, random, sys, time

ART = r"""
                  -`
                 .o+`
                `ooo/
               `+oooo:
              `+oooooo:
              -+oooooo+:
            `/:-:++oooo+:
           `/++++/+++++++:
          `/++++++++++++++:
         `/+++ooooooooooooo/`
        ./ooosssso++osssssso+`
       .oossssso-````/ossssss+`
      -osssssso.      :ssssssso.
     :osssssss/        osssso+++.
    /ossssssss/        +ssssooo/-
  `/ossssso+/:-        -:/+osssso+-
 `+sso+:-`                 `.-/+oso:
`++:.                           `-/+/
.`                                 `
""".strip("\n").split("\n")
H, W = len(ART), max(map(len, ART))
CELLS = [(y, x, c) for y, row in enumerate(ART) for x, c in enumerate(row) if c != " "]
NOISE = "+/:-.`o"

# Each effect maps a cell to the moment (0..1) it appears.
def eff_dissolve(y, x, i): return (i * 7919 % len(CELLS)) / len(CELLS)
def eff_wipe_down(y, x, i): return y / H
def eff_wipe_side(y, x, i): return x / W
def eff_center(y, x, i):   return min(1, math.hypot((x - W / 2) / W, (y - H / 2) / H) * 1.6)
def eff_type(y, x, i):     return i / len(CELLS)
def eff_rain(y, x, i):     return ((x * 37 % 11) / 11) * 0.6 + y / H * 0.4
EFFECTS = [eff_dissolve, eff_wipe_down, eff_wipe_side, eff_center, eff_type, eff_rain]

BUILD, HOLD, FADE, REST = 3.0, 4.0, 3.0, 1.0

# glyph styles: map the logo's shading (0 light .. 3 dense); None = original letters
STYLES = [None, "░▒▓█", "··•●", "0101", "⠂⠒⠖⠿", "-+##"]
def density(c): return 0 if c in ".`-" else 1 if c in ":/" else 2 if c == "+" else 3
def glyph(style, i, x, c):
    if style is None: return c
    return style[(i + x) % 2 * 3] if style == "0101" else style[density(c)]

def main(scr):
    curses.curs_set(0); scr.nodelay(True)
    curses.mousemask(curses.ALL_MOUSE_EVENTS | curses.REPORT_MOUSE_POSITION)
    sys.stdout.write("\033[?1003h"); sys.stdout.flush()
    curses.start_color(); curses.use_default_colors()
    curses.init_pair(1, 255, -1); curses.init_pair(2, 245, -1); curses.init_pair(3, 239, -1)
    start = time.time()
    try:
        while True:
            appear = random.choice(EFFECTS); vanish = random.choice(EFFECTS)
            style = None if random.random() < 0.35 else random.choice(STYLES[1:])
            order_in = [appear(y, x, i) for i, (y, x, _) in enumerate(CELLS)]
            order_out = [vanish(y, x, i) for i, (y, x, _) in enumerate(CELLS)]
            t0 = time.time()
            while (t := time.time() - t0) < BUILD + HOLD + FADE + REST:
                h, w = scr.getmaxyx()
                oy, ox = (h - H) // 2, (w - W) // 2
                scr.erase()
                for i, (y, x, c) in enumerate(CELLS):
                    if t < BUILD:            d = t / BUILD - order_in[i]          # >0 = visible
                    elif t < BUILD + HOLD:   d = 1
                    elif t < BUILD + HOLD + FADE: d = order_out[i] - (t - BUILD - HOLD) / FADE
                    else:                    d = -1
                    if d <= 0: continue
                    pair = 1 if d > 0.12 else 2 if d > 0.05 else 3
                    ch = glyph(style, i, x, c) if d > 0.06 else random.choice(NOISE)
                    if 0 <= oy + y < h and 0 <= ox + x < w - 1:
                        scr.addstr(oy + y, ox + x, ch, curses.color_pair(pair))
                scr.refresh()
                k = scr.getch()
                if k not in (-1, curses.KEY_RESIZE) and time.time() - start > 1.0:
                    return
                time.sleep(1 / 30)
    finally:
        sys.stdout.write("\033[?1003l"); sys.stdout.flush()

curses.wrapper(main)
