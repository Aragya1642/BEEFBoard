#!/usr/bin/env python3
"""Send a .srec to the BEEFBoard firmware-update master over the VCP.
Protocol: 4-byte little-endian length, then the raw file bytes.
Usage: python send_srec.py <COMx> <file.srec> [baud]   (needs: pip install pyserial)"""
import sys, struct, time, serial

port = sys.argv[1]
path = sys.argv[2]
baud = int(sys.argv[3]) if len(sys.argv) > 3 else 115200

data = open(path, "rb").read()          # binary mode — do NOT translate newlines
with serial.Serial(port, baud, timeout=2) as s:
    time.sleep(0.2)
    s.reset_input_buffer()
    s.write(struct.pack("<I", len(data)))
    s.write(data)
    s.flush()
    print(f"sent {len(data)} bytes; waiting for response...")
    t0 = time.time()                        # start timing AFTER the send completes
    while time.time() - t0 < 25:            # generous window for connect timeout (~5 s)
        ln = s.readline()
        if ln:
            sys.stdout.write(ln.decode(errors="replace")); sys.stdout.flush()
            if b"UPDATE" in ln:             # stop as soon as the result prints
                break
