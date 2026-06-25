#!/usr/bin/env python3
"""
USB-CANFD Monitor - a simple GUI to watch incoming CAN / CAN FD traffic and
to transmit frames, built on the ZCAN secondary-development library
(libcontrolcanfd.so on Linux, ControlCANFD.dll on 64-bit Windows).

The ctypes structures and the open/baud/init/start/transmit/receive call
sequence mirror the vendor demo exactly, so the binary interface matches the
shipped library.

Run:
    sudo python3 can_monitor.py

Requirements:
    - 64-bit Python (the vendor library is x64).
    - tkinter   (ships with CPython on Windows; `sudo apt install python3-tk`
                 on Ubuntu).
    - The vendor library + its dependencies reachable from the working dir:
        Linux  : ./libcontrolcanfd.so  (also needs libusb-1.0; the device
                 usually needs udev rules or running with sufficient perms)
        Windows: ControlCANFD.dll      (plus the VC2008 runtime and any
                 sibling DLLs from the vendor package)

Tip: tick "Simulate (no hardware)" to exercise the whole UI without a device.
"""

import os
import sys
import time
import random
import platform
import threading
from collections import deque
from ctypes import (
    Structure, Union, c_uint, c_ubyte, c_ushort, c_ulong, c_long,
    c_ulonglong, c_void_p, byref, cdll,
)

import tkinter as tk
from tkinter import ttk, filedialog, messagebox


# --------------------------------------------------------------------------- #
# Library constants (from the vendor demo)
# --------------------------------------------------------------------------- #
VCI_USBCAN2 = 41                 # device_type used by the demo
STATUS_OK = 1
INVALID_DEVICE_HANDLE = 0
INVALID_CHANNEL_HANDLE = 0
TYPE_CAN = 0
TYPE_CANFD = 1

# Baud-rate menus, label -> integer value (from the manual's property list)
ABIT_BAUDS = [
    ("1 Mbps", 1000000), ("800 kbps", 800000), ("500 kbps", 500000),
    ("250 kbps", 250000), ("125 kbps", 125000), ("100 kbps", 100000),
    ("50 kbps", 50000),
]
DBIT_BAUDS = [
    ("5 Mbps", 5000000), ("4 Mbps", 4000000), ("2 Mbps", 2000000),
    ("1 Mbps", 1000000), ("800 kbps", 800000), ("500 kbps", 500000),
    ("250 kbps", 250000), ("125 kbps", 125000), ("100 kbps", 100000),
]
CANFD_STANDARDS = [("ISO", 0), ("BOSCH", 1)]

# Valid CAN FD payload lengths (bytes)
CANFD_LENGTHS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 16, 20, 24, 32, 48, 64]

# UI tuning
RX_BUFFER_MAX = 50000     # bounded host buffer between RX thread and the UI
TREE_ROW_CAP = 5000       # max rows kept in the table (oldest trimmed)
DRAIN_MS = 50             # how often the UI pulls frames from the buffer
RX_IDLE_SLEEP = 0.002     # RX-thread sleep when the device has no frames
MIN_PERIODIC_MS = 10      # floor for the cyclic-send interval


# --------------------------------------------------------------------------- #
# ctypes structures (verbatim from the demo so the ABI matches)
# --------------------------------------------------------------------------- #
class _ZCAN_CHANNEL_CAN_INIT_CONFIG(Structure):
    _fields_ = [("acc_code", c_uint), ("acc_mask", c_uint), ("reserved", c_uint),
                ("filter", c_ubyte), ("timing0", c_ubyte),
                ("timing1", c_ubyte), ("mode", c_ubyte)]


class _ZCAN_CHANNEL_CANFD_INIT_CONFIG(Structure):
    _fields_ = [("acc_code", c_uint), ("acc_mask", c_uint), ("abit_timing", c_uint),
                ("dbit_timing", c_uint), ("brp", c_uint), ("filter", c_ubyte),
                ("mode", c_ubyte), ("pad", c_ushort), ("reserved", c_uint)]


class _ZCAN_CHANNEL_INIT_CONFIG(Union):
    _fields_ = [("can", _ZCAN_CHANNEL_CAN_INIT_CONFIG),
                ("canfd", _ZCAN_CHANNEL_CANFD_INIT_CONFIG)]


class ZCAN_CHANNEL_INIT_CONFIG(Structure):
    _fields_ = [("can_type", c_uint), ("config", _ZCAN_CHANNEL_INIT_CONFIG)]


class ZCAN_CAN_FRAME(Structure):
    _fields_ = [("can_id", c_uint, 29), ("err", c_uint, 1), ("rtr", c_uint, 1),
                ("eff", c_uint, 1), ("can_dlc", c_ubyte), ("__pad", c_ubyte),
                ("__res0", c_ubyte), ("__res1", c_ubyte), ("data", c_ubyte * 8)]


class ZCAN_CANFD_FRAME(Structure):
    _fields_ = [("can_id", c_uint, 29), ("err", c_uint, 1), ("rtr", c_uint, 1),
                ("eff", c_uint, 1), ("len", c_ubyte), ("brs", c_ubyte, 1),
                ("esi", c_ubyte, 1), ("__res", c_ubyte, 6), ("__res0", c_ubyte),
                ("__res1", c_ubyte), ("data", c_ubyte * 64)]


class ZCAN_Transmit_Data(Structure):
    _fields_ = [("frame", ZCAN_CAN_FRAME), ("transmit_type", c_uint)]


class ZCAN_Receive_Data(Structure):
    _fields_ = [("frame", ZCAN_CAN_FRAME), ("timestamp", c_ulonglong)]


class ZCAN_TransmitFD_Data(Structure):
    _fields_ = [("frame", ZCAN_CANFD_FRAME), ("transmit_type", c_uint)]


class ZCAN_ReceiveFD_Data(Structure):
    _fields_ = [("frame", ZCAN_CANFD_FRAME), ("timestamp", c_ulonglong)]


# --------------------------------------------------------------------------- #
# Pure helpers (no GUI / no hardware) - unit-testable
# --------------------------------------------------------------------------- #
def parse_hex_bytes(text):
    """Tolerant hex parser. Accepts '11 22 33', '1122 33AA', '0x11,0x22', etc."""
    if text is None:
        return []
    s = text.strip()
    if not s:
        return []
    for ch in (",", ";", "-", "_", "|", "\t"):
        s = s.replace(ch, " ")
    out = []
    for tok in s.split():
        t = tok.lower()
        if t.startswith("0x"):
            t = t[2:]
        if not t:
            continue
        if len(t) % 2:           # odd number of nibbles -> pad on the left
            t = "0" + t
        for i in range(0, len(t), 2):
            out.append(int(t[i:i + 2], 16))
    return out


def parse_can_id(text):
    """Parse a CAN id given in hex (with or without 0x) or decimal '#123'."""
    s = (text or "").strip().lower()
    if not s:
        raise ValueError("empty CAN id")
    if s.startswith("#"):
        return int(s[1:], 10)
    if s.startswith("0x"):
        s = s[2:]
    return int(s, 16)


def fd_round_up(n):
    """Round a byte count up to the next valid CAN FD payload length."""
    for length in CANFD_LENGTHS:
        if length >= n:
            return length
    return 64


def fmt_id(can_id, ext):
    return ("0x%08X" if ext else "0x%03X") % can_id


def fmt_flags(frame):
    flags = []
    if frame.get("ext"):
        flags.append("EXT")
    if frame.get("rtr"):
        flags.append("RTR")
    if frame.get("is_fd"):
        if frame.get("brs"):
            flags.append("BRS")
        if frame.get("esi"):
            flags.append("ESI")
    return " ".join(flags)


def fmt_data(data, dlc):
    return " ".join("%02X" % b for b in bytes(data)[:dlc])


# --------------------------------------------------------------------------- #
# Backends. Both expose: open(cfg) / close() / poll() -> [frame] / transmit(f)
# A "frame" is a dict:
#   {channel, is_fd, can_id, ext, rtr, brs, esi, data(bytes), dlc, ts(us)}
# --------------------------------------------------------------------------- #
class RealBackend:
    """Talks to the actual vendor library through ctypes."""

    def __init__(self):
        self.dll = None
        self.dev = None
        self.handles = {}                 # channel index -> channel handle
        self.lock = threading.Lock()      # serialize all library calls

    # -- setup ------------------------------------------------------------- #
    def _load(self, lib_path):
        self.dll = cdll.LoadLibrary(lib_path)
        d = self.dll
        d.ZCAN_OpenDevice.restype = c_void_p
        d.ZCAN_InitCAN.argtypes = (c_void_p, c_ulong, c_void_p)
        d.ZCAN_InitCAN.restype = c_void_p
        d.ZCAN_SetAbitBaud.argtypes = (c_void_p, c_ulong, c_ulong)
        d.ZCAN_SetDbitBaud.argtypes = (c_void_p, c_ulong, c_ulong)
        d.ZCAN_SetCANFDStandard.argtypes = (c_void_p, c_ulong, c_ulong)
        d.ZCAN_StartCAN.argtypes = (c_void_p,)
        d.ZCAN_ResetCAN.argtypes = (c_void_p,)
        d.ZCAN_CloseDevice.argtypes = (c_void_p,)
        d.ZCAN_Transmit.argtypes = (c_void_p, c_void_p, c_ulong)
        d.ZCAN_TransmitFD.argtypes = (c_void_p, c_void_p, c_ulong)
        d.ZCAN_GetReceiveNum.argtypes = (c_void_p, c_ulong)
        d.ZCAN_Receive.argtypes = (c_void_p, c_void_p, c_ulong, c_long)
        d.ZCAN_ReceiveFD.argtypes = (c_void_p, c_void_p, c_ulong, c_long)

    def open(self, cfg):
        self._load(cfg["lib_path"])
        with self.lock:
            self.dev = self.dll.ZCAN_OpenDevice(
                cfg["device_type"], cfg["device_index"], 0)
        if not self.dev:                  # 0 or None -> failed
            raise RuntimeError("ZCAN_OpenDevice failed (device not found / busy?)")

        channels = cfg["channels"]
        try:
            with self.lock:
                for ch in channels:
                    if self.dll.ZCAN_SetAbitBaud(self.dev, ch, cfg["abit"]) != STATUS_OK:
                        raise RuntimeError(f"SetAbitBaud failed on CAN{ch}")
                    if self.dll.ZCAN_SetDbitBaud(self.dev, ch, cfg["dbit"]) != STATUS_OK:
                        raise RuntimeError(f"SetDbitBaud failed on CAN{ch}")
                    if self.dll.ZCAN_SetCANFDStandard(
                            self.dev, ch, cfg["canfd_standard"]) != STATUS_OK:
                        raise RuntimeError(f"SetCANFDStandard failed on CAN{ch}")

                for ch in channels:
                    icfg = ZCAN_CHANNEL_INIT_CONFIG()
                    icfg.can_type = TYPE_CANFD
                    icfg.config.canfd.mode = 1 if cfg["listen_only"] else 0
                    icfg.config.canfd.filter = 0
                    icfg.config.canfd.acc_code = 0
                    icfg.config.canfd.acc_mask = 0xFFFFFFFF   # receive everything
                    icfg.config.canfd.brp = 0
                    icfg.config.canfd.pad = 0
                    icfg.config.canfd.reserved = 0
                    handle = self.dll.ZCAN_InitCAN(self.dev, ch, byref(icfg))
                    if not handle:
                        raise RuntimeError(f"ZCAN_InitCAN failed on CAN{ch}")
                    if self.dll.ZCAN_StartCAN(handle) != STATUS_OK:
                        raise RuntimeError(f"ZCAN_StartCAN failed on CAN{ch}")
                    self.handles[ch] = handle
        except Exception:
            self.close()
            raise

    def close(self):
        if self.dll is None:
            return
        with self.lock:
            for handle in self.handles.values():
                try:
                    self.dll.ZCAN_ResetCAN(handle)
                except Exception:
                    pass
            self.handles = {}
            if self.dev:
                try:
                    self.dll.ZCAN_CloseDevice(self.dev)
                except Exception:
                    pass
            self.dev = None

    # -- runtime ----------------------------------------------------------- #
    def _drain_channel(self, ch, handle, frames):
        # classic CAN
        n = self.dll.ZCAN_GetReceiveNum(handle, TYPE_CAN)
        if n and n > 0:
            arr = (ZCAN_Receive_Data * n)()
            got = self.dll.ZCAN_Receive(handle, byref(arr), n, 0)
            for i in range(got):
                fr = arr[i].frame
                dlc = min(int(fr.can_dlc), 8)
                frames.append({
                    "channel": ch, "is_fd": False,
                    "can_id": int(fr.can_id), "ext": bool(fr.eff),
                    "rtr": bool(fr.rtr), "brs": False, "esi": False,
                    "data": bytes(fr.data[j] for j in range(dlc)),
                    "dlc": dlc, "ts": int(arr[i].timestamp),
                })
        # CAN FD
        n = self.dll.ZCAN_GetReceiveNum(handle, TYPE_CANFD)
        if n and n > 0:
            arr = (ZCAN_ReceiveFD_Data * n)()
            got = self.dll.ZCAN_ReceiveFD(handle, byref(arr), n, 0)
            for i in range(got):
                fr = arr[i].frame
                dlc = min(int(fr.len), 64)
                frames.append({
                    "channel": ch, "is_fd": True,
                    "can_id": int(fr.can_id), "ext": bool(fr.eff),
                    "rtr": bool(fr.rtr), "brs": bool(fr.brs), "esi": bool(fr.esi),
                    "data": bytes(fr.data[j] for j in range(dlc)),
                    "dlc": dlc, "ts": int(arr[i].timestamp),
                })

    def poll(self):
        frames = []
        with self.lock:
            for ch, handle in self.handles.items():
                self._drain_channel(ch, handle, frames)
        return frames

    def transmit(self, f):
        handle = self.handles.get(f["channel"])
        if handle is None:
            raise RuntimeError(f"CAN{f['channel']} is not open")
        data = bytes(f["data"])
        if f["is_fd"]:
            msg = (ZCAN_TransmitFD_Data * 1)()
            msg[0].transmit_type = 0
            fr = msg[0].frame
            fr.can_id = f["can_id"]
            fr.eff = 1 if f["ext"] else 0
            fr.rtr = 1 if f["rtr"] else 0
            fr.brs = 1 if f["brs"] else 0
            fr.len = f["dlc"]
            for i in range(min(len(data), f["dlc"])):
                fr.data[i] = data[i]
            with self.lock:
                return int(self.dll.ZCAN_TransmitFD(handle, msg, 1))
        else:
            msg = (ZCAN_Transmit_Data * 1)()
            msg[0].transmit_type = 0
            fr = msg[0].frame
            fr.can_id = f["can_id"]
            fr.eff = 1 if f["ext"] else 0
            fr.rtr = 1 if f["rtr"] else 0
            fr.can_dlc = f["dlc"]
            for i in range(min(len(data), f["dlc"])):
                fr.data[i] = data[i]
            with self.lock:
                return int(self.dll.ZCAN_Transmit(handle, msg, 1))


class SimBackend:
    """Generates fake traffic so the UI can be used without hardware."""

    def __init__(self):
        self.channels = [0]
        self._last = 0.0
        self._counter = 0

    def open(self, cfg):
        self.channels = list(cfg["channels"]) or [0]
        self._last = time.time()

    def close(self):
        pass

    def poll(self):
        now = time.time()
        if now - self._last < 0.2:        # ~5 bursts/sec keeps it readable
            return []
        self._last = now
        self._counter = (self._counter + 1) & 0xFF
        ch = random.choice(self.channels)
        choice = self._counter % 3
        if choice == 0:                    # classic, standard id
            return [{"channel": ch, "is_fd": False, "can_id": 0x100, "ext": False,
                     "rtr": False, "brs": False, "esi": False,
                     "data": bytes([self._counter, 0x11, 0x22, 0x33,
                                    0x44, 0x55, 0x66, 0x77]),
                     "dlc": 8, "ts": int(now * 1e6)}]
        if choice == 1:                    # FD, standard id, BRS
            payload = bytes((self._counter + i) & 0xFF for i in range(16))
            return [{"channel": ch, "is_fd": True, "can_id": 0x200, "ext": False,
                     "rtr": False, "brs": True, "esi": False,
                     "data": payload, "dlc": 16, "ts": int(now * 1e6)}]
        # classic, extended id (J1939-style)
        return [{"channel": ch, "is_fd": False, "can_id": 0x18FF0001, "ext": True,
                 "rtr": False, "brs": False, "esi": False,
                 "data": bytes([0xDE, 0xAD, 0xBE, 0xEF]),
                 "dlc": 4, "ts": int(now * 1e6)}]

    def transmit(self, f):
        return 1                            # pretend the frame went out


# --------------------------------------------------------------------------- #
# GUI
# --------------------------------------------------------------------------- #
class App:
    def __init__(self, root):
        self.root = root
        self.root.title("USB-CANFD Monitor")
        self.root.geometry("1120x720")
        self.root.minsize(880, 560)

        # state
        self.backend = None
        self.rx_thread = None
        self._stop = threading.Event()
        self._buf = deque(maxlen=RX_BUFFER_MAX)
        self._buf_lock = threading.Lock()
        self.rx_count = 0
        self.tx_count = 0
        self._last_rx = 0
        self._periodic_job = None

        # tk variables
        self.var_lib = tk.StringVar(value=default_lib_path())
        self.var_devtype = tk.StringVar(value=str(VCI_USBCAN2))
        self.var_devindex = tk.StringVar(value="0")
        self.var_ch0 = tk.BooleanVar(value=True)
        self.var_ch1 = tk.BooleanVar(value=False)
        self.var_abit = tk.StringVar(value=ABIT_BAUDS[0][0])
        self.var_dbit = tk.StringVar(value=DBIT_BAUDS[0][0])
        self.var_std = tk.StringVar(value=CANFD_STANDARDS[0][0])
        self.var_listen = tk.BooleanVar(value=False)
        self.var_sim = tk.BooleanVar(value=False)

        self.var_tx_ch = tk.StringVar(value="0")
        self.var_tx_fd = tk.BooleanVar(value=False)
        self.var_tx_ext = tk.BooleanVar(value=False)
        self.var_tx_rtr = tk.BooleanVar(value=False)
        self.var_tx_brs = tk.BooleanVar(value=False)
        self.var_tx_id = tk.StringVar(value="100")
        self.var_tx_data = tk.StringVar(value="00 11 22 33 44 55 66 77")
        self.var_period = tk.StringVar(value="100")

        self.var_paused = tk.BooleanVar(value=False)
        self.var_autoscroll = tk.BooleanVar(value=True)
        self.var_status = tk.StringVar(value="Disconnected.")

        self._build_ui()
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self.root.after(DRAIN_MS, self._drain)
        self.root.after(1000, self._update_stats)

    # -- layout ------------------------------------------------------------ #
    def _build_ui(self):
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(1, weight=1)

        self._build_connection_bar()
        self._build_receive_area()
        self._build_transmit_area()
        self._build_status_bar()

    def _build_connection_bar(self):
        f = ttk.LabelFrame(self.root, text="Connection")
        f.grid(row=0, column=0, sticky="ew", padx=8, pady=(8, 4))
        for c in range(12):
            f.columnconfigure(c, weight=0)

        ttk.Label(f, text="Library:").grid(row=0, column=0, sticky="e", padx=4, pady=4)
        ttk.Entry(f, textvariable=self.var_lib, width=34).grid(
            row=0, column=1, columnspan=3, sticky="ew", padx=4, pady=4)
        ttk.Button(f, text="Browse...", command=self._browse_lib).grid(
            row=0, column=4, padx=4, pady=4)

        ttk.Label(f, text="Device type:").grid(row=0, column=5, sticky="e", padx=4)
        ttk.Entry(f, textvariable=self.var_devtype, width=6).grid(row=0, column=6, padx=2)
        ttk.Label(f, text="Index:").grid(row=0, column=7, sticky="e", padx=4)
        ttk.Entry(f, textvariable=self.var_devindex, width=5).grid(row=0, column=8, padx=2)

        ttk.Label(f, text="Channels:").grid(row=1, column=0, sticky="e", padx=4, pady=4)
        ttk.Checkbutton(f, text="CAN0", variable=self.var_ch0).grid(row=1, column=1, sticky="w")
        ttk.Checkbutton(f, text="CAN1", variable=self.var_ch1).grid(row=1, column=2, sticky="w")

        ttk.Label(f, text="Arb baud:").grid(row=1, column=3, sticky="e", padx=4)
        ttk.Combobox(f, textvariable=self.var_abit, width=10, state="readonly",
                     values=[lbl for lbl, _ in ABIT_BAUDS]).grid(row=1, column=4, padx=2)
        ttk.Label(f, text="Data baud:").grid(row=1, column=5, sticky="e", padx=4)
        ttk.Combobox(f, textvariable=self.var_dbit, width=10, state="readonly",
                     values=[lbl for lbl, _ in DBIT_BAUDS]).grid(row=1, column=6, padx=2)
        ttk.Label(f, text="FD std:").grid(row=1, column=7, sticky="e", padx=4)
        ttk.Combobox(f, textvariable=self.var_std, width=7, state="readonly",
                     values=[lbl for lbl, _ in CANFD_STANDARDS]).grid(row=1, column=8, padx=2)

        ttk.Checkbutton(f, text="Listen-only", variable=self.var_listen).grid(
            row=2, column=1, sticky="w", pady=(0, 6))
        ttk.Checkbutton(f, text="Simulate (no hardware)", variable=self.var_sim).grid(
            row=2, column=2, columnspan=2, sticky="w", pady=(0, 6))

        self.btn_connect = ttk.Button(f, text="Connect", command=self.connect)
        self.btn_connect.grid(row=2, column=5, sticky="ew", padx=4, pady=(0, 6))
        self.btn_disconnect = ttk.Button(f, text="Disconnect",
                                         command=self.disconnect, state="disabled")
        self.btn_disconnect.grid(row=2, column=6, sticky="ew", padx=4, pady=(0, 6))

    def _build_receive_area(self):
        f = ttk.LabelFrame(self.root, text="Received / transmitted frames")
        f.grid(row=1, column=0, sticky="nsew", padx=8, pady=4)
        f.columnconfigure(0, weight=1)
        f.rowconfigure(0, weight=1)

        cols = ("time", "dir", "ch", "type", "id", "flags", "dlc", "data")
        widths = (110, 40, 40, 60, 95, 90, 45, 560)
        anchors = ("w", "center", "center", "center", "w", "w", "center", "w")
        self.tree = ttk.Treeview(f, columns=cols, show="headings", selectmode="browse")
        headings = {
            "time": "Time", "dir": "Dir", "ch": "Ch", "type": "Type",
            "id": "CAN ID", "flags": "Flags", "dlc": "DLC", "data": "Data (hex)",
        }
        for col, w, anc in zip(cols, widths, anchors):
            self.tree.heading(col, text=headings[col])
            self.tree.column(col, width=w, anchor=anc, stretch=(col == "data"))
        self.tree.tag_configure("tx", foreground="#1565c0")
        self.tree.tag_configure("rx", foreground="#1b5e20")

        ysb = ttk.Scrollbar(f, orient="vertical", command=self.tree.yview)
        xsb = ttk.Scrollbar(f, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=ysb.set, xscrollcommand=xsb.set)
        self.tree.grid(row=0, column=0, sticky="nsew")
        ysb.grid(row=0, column=1, sticky="ns")
        xsb.grid(row=1, column=0, sticky="ew")

        bar = ttk.Frame(f)
        bar.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(4, 2))
        ttk.Button(bar, text="Clear", command=self.clear_table).pack(side="left", padx=2)
        ttk.Checkbutton(bar, text="Pause display", variable=self.var_paused).pack(
            side="left", padx=8)
        ttk.Checkbutton(bar, text="Auto-scroll", variable=self.var_autoscroll).pack(
            side="left", padx=8)
        ttk.Button(bar, text="Export CSV...", command=self.export_csv).pack(side="left", padx=8)
        self.lbl_counts = ttk.Label(bar, text="RX: 0   TX: 0   (0 f/s)")
        self.lbl_counts.pack(side="right", padx=4)

    def _build_transmit_area(self):
        f = ttk.LabelFrame(self.root, text="Transmit")
        f.grid(row=2, column=0, sticky="ew", padx=8, pady=4)

        ttk.Label(f, text="Channel:").grid(row=0, column=0, sticky="e", padx=4, pady=4)
        self.cmb_tx_ch = ttk.Combobox(f, textvariable=self.var_tx_ch, width=5,
                                      state="readonly", values=["0"])
        self.cmb_tx_ch.grid(row=0, column=1, padx=2)

        ttk.Checkbutton(f, text="CAN FD", variable=self.var_tx_fd,
                        command=self._sync_tx_flags).grid(row=0, column=2, padx=8)
        ttk.Checkbutton(f, text="Extended", variable=self.var_tx_ext).grid(row=0, column=3, padx=4)
        ttk.Checkbutton(f, text="RTR", variable=self.var_tx_rtr).grid(row=0, column=4, padx=4)
        self.chk_brs = ttk.Checkbutton(f, text="BRS", variable=self.var_tx_brs,
                                       state="disabled")
        self.chk_brs.grid(row=0, column=5, padx=4)

        ttk.Label(f, text="ID (hex):").grid(row=1, column=0, sticky="e", padx=4, pady=4)
        ttk.Entry(f, textvariable=self.var_tx_id, width=12).grid(row=1, column=1, padx=2)
        ttk.Label(f, text="Data (hex):").grid(row=1, column=2, sticky="e", padx=4)
        ttk.Entry(f, textvariable=self.var_tx_data).grid(
            row=1, column=3, columnspan=4, sticky="ew", padx=4)
        f.columnconfigure(6, weight=1)

        ttk.Button(f, text="Send", command=self.send_once).grid(
            row=1, column=7, padx=6, pady=4)

        ttk.Label(f, text="Period (ms):").grid(row=2, column=0, sticky="e", padx=4, pady=(0, 6))
        ttk.Entry(f, textvariable=self.var_period, width=8).grid(
            row=2, column=1, padx=2, pady=(0, 6))
        self.btn_periodic = ttk.Button(f, text="Start periodic", command=self.toggle_periodic)
        self.btn_periodic.grid(row=2, column=2, padx=6, pady=(0, 6), sticky="w")

    def _build_status_bar(self):
        bar = ttk.Frame(self.root)
        bar.grid(row=3, column=0, sticky="ew", padx=8, pady=(0, 8))
        self.dot = tk.Canvas(bar, width=12, height=12, highlightthickness=0)
        self._dot_id = self.dot.create_oval(2, 2, 10, 10, fill="#c62828", outline="")
        self.dot.pack(side="left", padx=(0, 6))
        ttk.Label(bar, textvariable=self.var_status).pack(side="left")

    # -- small UI helpers -------------------------------------------------- #
    def _browse_lib(self):
        path = filedialog.askopenfilename(
            title="Select vendor library",
            filetypes=[("Shared libraries", "*.so *.dll"), ("All files", "*.*")])
        if path:
            self.var_lib.set(path)

    def _sync_tx_flags(self):
        self.chk_brs.configure(state="normal" if self.var_tx_fd.get() else "disabled")
        if not self.var_tx_fd.get():
            self.var_tx_brs.set(False)

    def _set_connected_ui(self, connected):
        self.btn_connect.configure(state="disabled" if connected else "normal")
        self.btn_disconnect.configure(state="normal" if connected else "disabled")
        self.dot.itemconfigure(self._dot_id, fill="#2e7d32" if connected else "#c62828")

    def _status(self, text):
        self.var_status.set(text)

    # -- connect / disconnect --------------------------------------------- #
    def _read_config(self):
        channels = []
        if self.var_ch0.get():
            channels.append(0)
        if self.var_ch1.get():
            channels.append(1)
        if not channels:
            raise ValueError("Select at least one channel (CAN0 / CAN1).")
        abit = dict(ABIT_BAUDS)[self.var_abit.get()]
        dbit = dict(DBIT_BAUDS)[self.var_dbit.get()]
        std = dict(CANFD_STANDARDS)[self.var_std.get()]
        return {
            "lib_path": self.var_lib.get().strip(),
            "device_type": int(self.var_devtype.get()),
            "device_index": int(self.var_devindex.get()),
            "channels": channels,
            "abit": abit, "dbit": dbit, "canfd_standard": std,
            "listen_only": self.var_listen.get(),
        }

    def connect(self):
        if self.backend is not None:
            return
        try:
            cfg = self._read_config()
        except (ValueError, KeyError) as exc:
            messagebox.showerror("Invalid settings", str(exc))
            return

        backend = SimBackend() if self.var_sim.get() else RealBackend()
        try:
            backend.open(cfg)
        except Exception as exc:               # noqa: BLE001 - surface any failure
            messagebox.showerror("Connect failed", str(exc))
            return

        self.backend = backend
        self._stop.clear()
        self.rx_thread = threading.Thread(target=self._rx_loop, daemon=True)
        self.rx_thread.start()

        chans = [str(c) for c in cfg["channels"]]
        self.cmb_tx_ch.configure(values=chans)
        if self.var_tx_ch.get() not in chans:
            self.var_tx_ch.set(chans[0])

        self._set_connected_ui(True)
        mode = "simulation" if self.var_sim.get() else "device"
        listen = " (listen-only)" if cfg["listen_only"] else ""
        self._status(f"Connected to {mode}{listen}: CAN{', CAN'.join(chans)} "
                     f"@ {self.var_abit.get()} / {self.var_dbit.get()}.")

    def disconnect(self):
        if self.backend is None:
            return
        self._stop_periodic()
        self._stop.set()
        if self.rx_thread is not None:
            self.rx_thread.join(timeout=1.5)
        self.rx_thread = None
        try:
            self.backend.close()
        except Exception:
            pass
        self.backend = None
        self._set_connected_ui(False)
        self._status("Disconnected.")

    # -- receive path ------------------------------------------------------ #
    def _rx_loop(self):
        backend = self.backend
        while not self._stop.is_set():
            try:
                frames = backend.poll()
            except Exception as exc:           # noqa: BLE001
                self.root.after(0, self._on_rx_error, str(exc))
                return
            if frames:
                now = time.time()
                with self._buf_lock:
                    for fr in frames:
                        fr["dir"] = "Rx"
                        fr["host_t"] = now
                        self._buf.append(fr)
                        self.rx_count += 1
            else:
                time.sleep(RX_IDLE_SLEEP)

    def _on_rx_error(self, message):
        self._status(f"Receive error: {message}")
        messagebox.showerror("Receive error", message)
        self.disconnect()

    def _drain(self):
        with self._buf_lock:
            batch = list(self._buf)
            self._buf.clear()
        if batch and not self.var_paused.get():
            for fr in batch:
                self._insert_row(fr)
            self._trim_table()
            if self.var_autoscroll.get():
                self.tree.yview_moveto(1.0)
        self.root.after(DRAIN_MS, self._drain)

    def _insert_row(self, fr):
        t = time.strftime("%H:%M:%S", time.localtime(fr.get("host_t", time.time())))
        t += ".%03d" % int((fr.get("host_t", time.time()) % 1) * 1000)
        values = (
            t, fr["dir"], fr["channel"],
            "CANFD" if fr["is_fd"] else "CAN",
            fmt_id(fr["can_id"], fr["ext"]),
            fmt_flags(fr), fr["dlc"], fmt_data(fr["data"], fr["dlc"]),
        )
        tag = "tx" if fr["dir"] == "Tx" else "rx"
        self.tree.insert("", "end", values=values, tags=(tag,))

    def _trim_table(self):
        children = self.tree.get_children()
        excess = len(children) - TREE_ROW_CAP
        if excess > 0:
            for iid in children[:excess]:
                self.tree.delete(iid)

    def clear_table(self):
        self.tree.delete(*self.tree.get_children())

    def export_csv(self):
        rows = self.tree.get_children()
        if not rows:
            messagebox.showinfo("Export CSV", "Nothing to export yet.")
            return
        path = filedialog.asksaveasfilename(
            defaultextension=".csv", filetypes=[("CSV", "*.csv")],
            title="Export trace")
        if not path:
            return
        try:
            with open(path, "w", encoding="utf-8", newline="") as fh:
                fh.write("Time,Dir,Ch,Type,ID,Flags,DLC,Data\n")
                for iid in rows:
                    vals = self.tree.item(iid, "values")
                    fh.write(",".join('"%s"' % str(v) for v in vals) + "\n")
            self._status(f"Exported {len(rows)} rows to {os.path.basename(path)}.")
        except OSError as exc:
            messagebox.showerror("Export failed", str(exc))

    # -- transmit path ----------------------------------------------------- #
    def _collect_tx_frame(self):
        if self.backend is None:
            raise RuntimeError("Not connected.")
        is_fd = self.var_tx_fd.get()
        ext = self.var_tx_ext.get()
        rtr = self.var_tx_rtr.get()
        brs = self.var_tx_brs.get() and is_fd
        can_id = parse_can_id(self.var_tx_id.get())
        limit = 0x1FFFFFFF if ext else 0x7FF
        if can_id < 0 or can_id > limit:
            raise ValueError("CAN id out of range for the selected frame format.")

        data = parse_hex_bytes(self.var_tx_data.get())
        for b in data:
            if b > 0xFF:
                raise ValueError("Data byte out of range (00-FF).")
        if rtr:
            data = []                          # remote frames carry no data
        if is_fd:
            dlc = fd_round_up(len(data))
        else:
            if len(data) > 8:
                data = data[:8]
                self._status("Note: classic CAN payload truncated to 8 bytes.")
            dlc = len(data)
        data = bytes(data[:dlc]) + bytes(max(0, dlc - len(data)))
        return {
            "channel": int(self.var_tx_ch.get()),
            "is_fd": is_fd, "can_id": can_id, "ext": ext, "rtr": rtr,
            "brs": brs, "esi": False, "data": data, "dlc": dlc,
            "ts": 0,
        }

    def _send(self, silent=False):
        try:
            frame = self._collect_tx_frame()
        except (ValueError, RuntimeError) as exc:
            if not silent:
                messagebox.showerror("Cannot send", str(exc))
            else:
                self._status(f"Send skipped: {exc}")
            return False
        try:
            sent = self.backend.transmit(frame)
        except Exception as exc:               # noqa: BLE001
            self._status(f"Send failed: {exc}")
            if not silent:
                messagebox.showerror("Send failed", str(exc))
            return False
        if sent and sent >= 1:
            frame["dir"] = "Tx"
            frame["host_t"] = time.time()
            with self._buf_lock:
                self._buf.append(frame)
            self.tx_count += 1
            return True
        self._status("Send failed: device reported 0 frames sent.")
        return False

    def send_once(self):
        if self._send(silent=False):
            self._status("Frame sent.")

    def toggle_periodic(self):
        if self._periodic_job is not None:
            self._stop_periodic()
            return
        if self.backend is None:
            messagebox.showerror("Cannot send", "Not connected.")
            return
        try:
            interval = max(MIN_PERIODIC_MS, int(self.var_period.get()))
        except ValueError:
            messagebox.showerror("Invalid period", "Period must be an integer (ms).")
            return
        # validate the frame once up front
        try:
            self._collect_tx_frame()
        except (ValueError, RuntimeError) as exc:
            messagebox.showerror("Cannot send", str(exc))
            return
        self.btn_periodic.configure(text="Stop periodic")
        self._status(f"Periodic send every {interval} ms.")
        self._run_periodic(interval)

    def _run_periodic(self, interval):
        self._send(silent=True)
        self._periodic_job = self.root.after(interval, self._run_periodic, interval)

    def _stop_periodic(self):
        if self._periodic_job is not None:
            self.root.after_cancel(self._periodic_job)
            self._periodic_job = None
            self.btn_periodic.configure(text="Start periodic")

    # -- stats ------------------------------------------------------------- #
    def _update_stats(self):
        rate = self.rx_count - self._last_rx
        self._last_rx = self.rx_count
        self.lbl_counts.configure(
            text=f"RX: {self.rx_count}   TX: {self.tx_count}   ({rate} f/s)")
        self.root.after(1000, self._update_stats)

    # -- shutdown ---------------------------------------------------------- #
    def _on_close(self):
        try:
            self.disconnect()
        finally:
            self.root.destroy()


def default_lib_path():
    if platform.system() == "Windows":
        return r"2_CAN_Bus_Analyzer\USB-CAN-FD_Library\x64\ControlCANFD.dll"
    return "./libcontrolcanfd.so"


def main():
    root = tk.Tk()
    App(root)
    root.mainloop()


if __name__ == "__main__":
    main()