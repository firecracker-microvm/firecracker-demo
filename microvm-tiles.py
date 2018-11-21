"""
A demo script for visualising on-host microVM network activity.

Will read bytes recieved by the host on microVM tun/tap devices, as per
`/proc/net/dev` file, and then use that data to color a cell on the terminal.

The terminal screen is refreshed periodically. The brigher a cell is colored,
the more bytes the host recieved from that microVM. The brightness range is
scaled based on the maximum amount of bytes a microvm has sent in that refresh
cycle.
"""

#!/usr/bin/python3


import curses
import re
import time

MAX_MICROVMS = 4096
COLOR_BLACK = 101
MICROVM_TAP_REGEX = r'fc-(\d+)-tap'


def render_microvms(stdscr):
    # Put key-grabbing in no-wait mode.
    stdscr.nodelay(True)

    # Clear screen
    stdscr.clear()

    # Create a gradient "color palette" with 100 color pairs, from dark grey to
    # Amazon orange. Color pair 0 is reserved in curses, we'll start from 1.
    for shade in range (1, 101):
        curses.init_color(shade, 200 + shade * 8, 200 + int(shade * 4.8), 208)
        curses.init_pair(shade, shade, shade)

    # Black for background.
    curses.init_color(COLOR_BLACK, 0, 0, 0)
    curses.init_pair(COLOR_BLACK, COLOR_BLACK, COLOR_BLACK)

    # Seed value for the last iteration's microVM network interface activty.
    last_rx = [0] * MAX_MICROVMS
    delta_rx = [0] * MAX_MICROVMS

    # Blinky loop of infinite microVM activity rendering
    # TODO: End loop on any key press (Ctrl+C required now).
    last_iface_idx = 0
    while True:
        # Reads the latest received bytes on the microVMs' tun/tap interfaces
        # and computes the delta against the last iteration, as well as the
        # highest delta in this iteration.
        with open('/proc/net/dev') as net_iface_list:
            # The first two lines of `/proc/net/dev` are headers.
            next(net_iface_list)
            next(net_iface_list)

            max_rx = 0
            for iface_line in net_iface_list:
                # Only operate microVM tun/tap lines, and extract their index
                # (they show up in an arbitrary order in the file).
                scan_for_microvm_tap = re.match(MICROVM_TAP_REGEX, iface_line)
                if not scan_for_microvm_tap:
                    continue

                iface_idx = int(scan_for_microvm_tap.group(1))

                current_rx = int(iface_line.split()[1])
                delta_rx[iface_idx] = current_rx - last_rx[iface_idx]
                last_rx[iface_idx] = current_rx

                if delta_rx[iface_idx] > max_rx:
                    max_rx = delta_rx[iface_idx]

                if last_iface_idx < iface_idx:
                    last_iface_idx = iface_idx

        # "Render" all microVMs. Their brightness is proportional to
        # delta_rx_bytes/max_rx_bytes
        for i in range(0, curses.LINES - 1):
            for j in range(0, curses.COLS):
                slot_idx = i * curses.COLS + j
                # If there's no microVM there yet, use black
                if slot_idx > last_iface_idx:
                    microvm_color = COLOR_BLACK 
                else:
                    # Inactive microvms get a grey color.
                    microvm_color = 1
                    if max_rx > 0:
                        microvm_color += int(99 * delta_rx[slot_idx] / max_rx)

                stdscr.addstr(i, j, ' ', curses.color_pair(microvm_color))

        stdscr.refresh()
        time.sleep(0.25)


# Run the curses "rendering" loop in the terminal, and clean up after.
curses.wrapper(render_microvms)

