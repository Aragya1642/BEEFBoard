# BEEFBoard — CAN Firmware-Update (OTA) System

Flash application firmware onto a target STM32 over a **CAN bus**, by streaming a
`.srec` file from a PC to a "master" board over USB, which relays it to the target
using **XCP-on-CAN** and the **OpenBLT** bootloader.

```
Host PC ──USB──► Master (NUCLEO-H753ZI) ──CAN──► Target (NUCLEO-H743ZI)
 send_srec.py        relay + XCP master            OpenBLT bootloader
```

**Status:** ✅ End-to-end flashing is working and verified — a generic application
and the OpenBLT demo app have both been flashed onto the target over CAN
(`UPDATE OK`), with the full XCP handshake confirmed on a CAN analyzer.

---

## Table of contents

1. [How it works](#how-it-works)
2. [Repository layout](#repository-layout)
3. [Prerequisites](#prerequisites)
4. [Hardware setup & wiring](#hardware-setup--wiring)
5. [One-time setup](#one-time-setup)
6. [Quick start — flashing firmware](#quick-start--flashing-firmware)
7. [Building your own application for this bootloader](#building-your-own-application-for-this-bootloader) ⭐
8. [The wire protocol](#the-wire-protocol)
9. [Configuration reference](#configuration-reference)
10. [Troubleshooting](#troubleshooting)
11. [Lessons learned (bugs we hit and fixed)](#lessons-learned-bugs-we-hit-and-fixed)
12. [Limitations & future work](#limitations--future-work)
13. [References](#references)

---

## How it works

The system has three pieces. The host sends a firmware image to the master; the
master buffers it, then acts as an XCP master to program the target's flash over CAN.

```
┌──────────┐  USB-VCP (USART3)          ┌────────────────────────┐  FDCAN, 500 kbit/s   ┌──────────────────────────┐
│ Host PC  │  115200 8N1                │ Master  NUCLEO-H753ZI   │  classic frames      │ Target  NUCLEO-H743ZI    │
│          │ ─────────────────────────► │                        │ ───────────────────► │                          │
│send_srec │  [4-byte LE length]        │ • USART3 RX → stream    │  TX id 0x667         │ • OpenBLT bootloader     │
│   .py    │  [ raw .srec bytes ]       │ • RAM-disk FatFS        │                      │   (0x08000000, 128 KB)   │
│          │                            │ • app.srec written      │ ◄─────────────────── │ • your app @ 0x08020000  │
│          │ ◄───── status text ─────── │ • LibMicroBLT XCP master │  responses id 0x7E1  │                          │
└──────────┘  READY / RECEIVED /        └────────────────────────┘                      └──────────────────────────┘
              VERIFY OK / UPDATE OK
```

1. **Host → Master (USB-VCP).** [`send_srec.py`](3_Python_Scripts/send_srec.py) opens the
   master's ST-Link virtual COM port, sends a **4-byte little-endian length** header,
   then the raw `.srec` bytes.
2. **Master buffers the file.** A FreeRTOS task on the master receives the stream into a
   **RAM-disk FatFS** (in AXI SRAM) and writes it to a file named `app.srec`, verifying
   the byte count.
3. **Master → Target (XCP-on-CAN).** The master calls `UpdateFirmware("app.srec", 0)`
   (LibMicroBLT), which connects to the target's OpenBLT bootloader over CAN and programs
   the application flash region.
4. **Target runs the new app.** When the bootloader has a valid program and no backdoor
   request, it jumps to the application at `0x08020000`.

---

## Repository layout

```
BEEFBoard/
├── README.md                       ← you are here
├── .gitmodules                     ← git submodules: openblt, libmicroblt
├── .venv/                          ← Python venv for the host tool (pyserial)
│
├── 1_Embedded/
│   ├── CAN_Firmware_Flashing/
│   │   ├── CAN_Firmware_Flashing_Master/   ← MASTER  (NUCLEO-H753ZI)
│   │   │   ├── Core/Src/main.c             ← FwUpdateTask: UART RX → FatFS → flash
│   │   │   ├── App/blt_port.c              ← XCP-on-CAN port (FDCAN, ids 0x667/0x7E1)
│   │   │   ├── App/update.c                ← LibMicroBLT UpdateFirmware() wrapper
│   │   │   ├── FatFs/ffdiskio.c            ← RAM-disk backing store (AXI SRAM)
│   │   │   └── STM32H753ZITX_FLASH.ld
│   │   └── CAN_Firmware_Flashing_Slave/    ← TARGET  (NUCLEO-H743ZI)
│   │       ├── Boot/                       ← OpenBLT bootloader  (flash @ 0x08000000)
│   │       │   ├── App/blt_conf.h          ← bootloader config (CAN, ids, baud) — EDIT HERE
│   │       │   ├── App/hooks.c             ← PC13 backdoor, LED blink
│   │       │   └── STM32H743ZITX_FLASH.ld
│   │       └── Prog/                       ← OpenBLT demo app   (flash @ 0x08020000)
│   │           └── STM32H743ZITX_FLASH.ld
│   │
│   ├── Generic_Code/                       ← template app for the bootloader (@ 0x08020000)
│   ├── openblt/                            ← submodule: OpenBLT bootloader framework
│   └── libmicroblt/                        ← submodule: XCP-on-CAN master library
│
├── 2_CAN_Bus_Analyzer/                     ← USB-CAN-FD monitor (debugging)
├── 3_Python_Scripts/
│   └── send_srec.py                        ← the host updater tool
└── 4_KiCAD_Files/                          ← PCB design
```

> MicroTBX (a LibMicroBLT dependency) is vendored inside the master project rather than
> referenced as a submodule.

---

## Prerequisites

### Hardware
- **Master:** ST NUCLEO-H753ZI
- **Target:** ST NUCLEO-H743ZI
- **2× CAN transceivers** (e.g. TJA1051/TJA1042/SN65HVD23x) — the MCU FDCAN pins are
  logic-level and **cannot** drive a bus directly.
- **2× 120 Ω** termination resistors (one at each end of the bus).
- Jumper wires for CANH / CANL / GND, and 2× USB cables (one per Nucleo).

### Software
- **STM32CubeIDE** (GCC / arm-none-eabi toolchain) — to build and SWD-flash the firmware.
- **Python 3.8+** with **pyserial** — for the host tool.

### Python environment
```bash
# from the repo root
python -m venv .venv
.venv\Scripts\activate            # Windows (PowerShell/CMD)
# source .venv/bin/activate       # Linux/macOS
pip install pyserial
```
The only dependency is `pyserial`. (The committed `.venv` was created with `uv`; a plain
`venv` works identically.)

---

## Hardware setup & wiring

Both boards use **FDCAN1** on the same pins:

| Signal      | Pin  | Alternate function |
|-------------|------|--------------------|
| FDCAN1_RX   | PD0  | AF9                |
| FDCAN1_TX   | PD1  | AF9                |

Wire it up like this:

```
   Master H753ZI                              Target H743ZI
   PD1 (TX) ─► [CAN xcvr] ─┬─ CANH ───────────┬─ [CAN xcvr] ◄─ PD1 (TX)
   PD0 (RX) ◄─ [        ] ─┴─ CANL ───────────┴─ [        ] ─► PD0 (RX)
   GND ───────────────────────── common GND ──────────────────────── GND
                            120 Ω ┤            ├ 120 Ω   (one at each bus end)
```

Checklist (these are the usual reasons a freshly-wired bus stays silent):
- ✅ A **transceiver on each board** (not MCU pins straight to the bus).
- ✅ **120 Ω** across CANH/CANL at **both** ends of the bus.
- ✅ **Common ground** between the two boards.
- ✅ CANH↔CANH and CANL↔CANL (not swapped).
- ✅ If your transceiver has an `STBY`/`S`/`EN` pin, drive it to **normal mode** — the
  firmware does not configure any such pin.

USB: the **master's** USB (ST-Link VCP) is used for the firmware transfer. The target's
USB is only needed to SWD-flash its bootloader the first time.

---

## One-time setup

### 1. Flash the OpenBLT bootloader onto the target (SWD)
The bootloader is programmed **once** with a debugger; thereafter the app is updated over CAN.

1. Open `1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Slave/Boot/` in STM32CubeIDE.
2. Build it, then **Run/Debug** to flash via the on-board ST-Link.
3. On reset with **no valid app**, the bootloader stays active and the LED blinks fast
   (~5 Hz) — that's your "waiting for firmware" indicator.

### 2. Build and flash the master firmware (SWD)
1. Open `1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/` in STM32CubeIDE.
2. Build and flash it to the H753ZI via its ST-Link.

### 3. Set up the Python environment
See [Python environment](#python-environment) above.

---

## Quick start — flashing firmware

With the bootloader flashed, the boards wired, and the **target in the bootloader**
(fast LED blink — hold **PC13** during reset if needed):

```powershell
& .\.venv\Scripts\python.exe .\3_Python_Scripts\send_srec.py COM9 `
  .\1_Embedded\CAN_Firmware_Flashing\CAN_Firmware_Flashing_Slave\Prog\Debug\demoprog_stm32h743.srec
```
(replace `COM9` with the master's COM port)

Expected output — the happy path:
```
sent 85210 bytes; waiting for response...
RECEIVED 85210 / 85210 bytes
VERIFY app.srec = 85210 bytes OK
UPDATE OK
```

On a CAN analyzer you'll see the XCP exchange: master `CONNECT` (`FF 00` on `0x667`),
target reply (`FF 10 …` on `0x7E1`), then a stream of program/verify commands.

> ⚠️ **Send a real `.srec`** (file begins with `S0`/`S1`/`S2`/`S3`). A `.symbolsrec` is a
> *symbol dump*, not firmware — it is not flashable. See [Troubleshooting](#troubleshooting).

---

## Building your own application for this bootloader ⭐

This is the part that trips everyone up. The bootloader occupies the **first 128 KB** of
flash, so **your application cannot live at the default `0x08000000`** — it must be linked
at **`0x08020000`** and relocate its vector table to match. `Generic_Code/` is set up as a
working template; replicate these two changes in any new project.

### Memory map (target, H743 — 2 MB flash)

| Region        | Address range            | Size    | Contents              |
|---------------|--------------------------|---------|-----------------------|
| Bootloader    | `0x08000000`–`0x0801FFFF`| 128 KB  | OpenBLT (flash via SWD, once) |
| **Application** | `0x08020000`–`0x081FFFFF`| 1920 KB | **your firmware (flashed over CAN)** |

### 1. Linker script — set the FLASH origin
In your `STM32H743ZITX_FLASH.ld`:
```ld
MEMORY
{
  FLASH (rx) : ORIGIN = 0x08020000, LENGTH = 2048K - 128K   /* = 1920K */
  /* ...RAM regions unchanged... */
}
```

### 2. Vector table (VTOR) — point the CPU at your vectors
After the bootloader jumps to your app, the CPU must use **your** vector table, or no
interrupts/SysTick will work. Two equivalent ways:

**Option A — CubeMX/`system_stm32h7xx.c` (what `Generic_Code` uses):**
```c
/* Uncomment the relocation block ... */
#define USER_VECT_TAB_ADDRESS
/* ... and set the offset to 128 KB: */
#define VECT_TAB_OFFSET  0x00020000U   /* FLASH_BANK1_BASE | 0x20000 = 0x08020000 */
```
This makes `SystemInit()` set `SCB->VTOR = 0x08020000`.

**Option B — explicit, in `main()` (what the OpenBLT demo app does):**
```c
extern uint32_t g_pfnVectors[];
SCB->VTOR = (uint32_t)&g_pfnVectors[0];   /* resolves to 0x08020000 */
```

### 3. Build, verify the address, flash
Do a **clean build** (a stale `.srec` from before the linker change is a classic gotcha),
then confirm the image really starts at `0x08020000` — the first `S3` record should read
`S315 08020000 …`:
```bash
head -3 ./1_Embedded/Generic_Code/Debug/Generic_Code.srec
# S0..(header)
# S315 08020000 ....   ← must be 08020000, NOT 08000000
```
Then flash it exactly like the demo app in [Quick start](#quick-start--flashing-firmware).

> 💡 Keep your app's clock setup compatible with the bootloader's assumptions (8 MHz HSE,
> 500 kbit/s CAN). The flashing itself runs entirely in the bootloader, so a mismatched
> app clock won't break the *update* — only the app's own peripheral timing once it boots.

---

## The wire protocol

### Host → Master (USB-VCP, USART3, 115200 8N1)
A length-prefixed raw file:
```
┌─────────────────────────┬───────────────────────────────────┐
│ 4 bytes: length (LE u32) │ N bytes: raw .srec file contents  │
└─────────────────────────┴───────────────────────────────────┘
```
- The master prints `READY:` and waits for the 4-byte length, then streams the body to
  `app.srec` on its RAM-disk.
- Length is validated: `0 < len ≤ 440 KB`. Out of range → `BAD LENGTH: <value>` and it
  resets to `READY`.
- Status messages: `READY` → `RECEIVED a/b bytes` → `VERIFY … OK|MISMATCH` →
  `UPDATE OK|FAILED`.
- **`send_srec.py` is required** — it prepends the length header. Sending raw bytes (e.g. a
  serial terminal paste) desyncs the framing and triggers a `BAD LENGTH` flood.

### Master → Target (XCP-on-CAN)
- **Protocol:** XCP 1.0 over CAN (OpenBLT).
- **Frames:** classic CAN, 8-byte max, **500 kbit/s**.
- **IDs:** master→target `0x667`, target→master `0x7E1` (OpenBLT defaults).

---

## Configuration reference

### CAN identifiers & bus
| Setting            | Value          | Master location                         | Target location                        |
|--------------------|----------------|-----------------------------------------|----------------------------------------|
| TX (master→target) | `0x667`        | [`blt_port.c`](1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/App/blt_port.c) `BLT_XCP_CAN_TX_ID` | `blt_conf.h` `BOOT_COM_CAN_RX_MSG_ID` |
| RX (target→master) | `0x7E1`        | `blt_port.c` `BLT_XCP_CAN_RX_ID`        | `blt_conf.h` `BOOT_COM_CAN_TX_MSG_ID`  |
| Bitrate            | 500 kbit/s     | FDCAN nominal timing                    | `blt_conf.h` `BOOT_COM_CAN_BAUDRATE`   |
| Frame format       | Classic CAN    | `FDCAN_CLASSIC_CAN`                     | `BOOT_COM_CAN_FD_ENABLE = 0`           |
| Controller         | FDCAN1 (PD0/PD1) | —                                     | `BOOT_COM_CAN_CHANNEL_INDEX = 0`       |

### Clocks behind the 500 kbit/s (they differ but both resolve to 500 k)
| Board  | FDCAN kernel clock | Derivation                              | Bit timing (prescaler / Tseg1 / Tseg2) | Result |
|--------|--------------------|-----------------------------------------|----------------------------------------|--------|
| Master | **50 MHz** (PLL1Q) | HSI 64 → /M4 = 16 → ×9.375 (N9 + FRACN 3072) = 150 → /Q3 | 1 / 86 / 13 → 100 tq | 500 k |
| Target | **80 MHz** (PLL2Q) | HSE 8 → /M1 = 8 → ×N20 = 160 → /Q2      | auto (OpenBLT search) → 160 tq          | 500 k |

### Host tool
| Setting        | Value / note                                        |
|----------------|-----------------------------------------------------|
| Usage          | `python send_srec.py <COMx> <file.srec> [baud]`     |
| Default baud   | 115200                                              |
| Framing        | 4-byte little-endian length, then raw file bytes    |
| Response window| waits up to ~25 s, stops on `UPDATE`                |

### Master RAM-disk
- FatFS backing buffer in **AXI SRAM** (`RAM_D1` @ `0x24000000`), ~448 KB.
- Max accepted file size: **440 KB** (`SREC_MAX_FILE_SIZE`).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `BAD LENGTH: <huge number>` (flooding) | Framing desynced — raw bytes sent without the length header, a stray byte before the header, or the wrong file | Use `send_srec.py` (it adds the header); reset the board / re-open the port for a clean start |
| `BAD LENGTH` once, then works after retry | A stale byte was queued before your length prefix | Re-open the port / reset the master so the buffer starts clean |
| Master parses but flashing never starts; file is a `.symbolsrec` | That's a symbol dump, not firmware | Flash a real `.srec` (`objcopy -O srec`), beginning with `S0/S1/S2/S3` |
| `Could not open port` / port busy | A serial monitor owns the COM port | Close all other serial tools — only one program can own the port |
| `UPDATE FAILED (connect timeout?)`, **no `0x7E1`** on the analyzer | Target not in the bootloader, or it can't see/drive the bus | Confirm fast LED blink (hold **PC13** + reset to force bootloader); check transceiver enable pin, common GND, termination, CANH/CANL |
| `UPDATE FAILED`, but **`0x667` and `0x7E1` both** on the analyzer | XCP connected but programming failed — usually the app is linked at the wrong address | Re-link the app at `0x08020000` and fix VTOR (see [Building your own application](#building-your-own-application-for-this-bootloader)); clean-build so the `.srec` is regenerated |
| App flashes (`UPDATE OK`) but hard-faults / no interrupts on boot | VTOR not relocated | Set `VECT_TAB_OFFSET = 0x00020000` (or `SCB->VTOR` in `main()`) |
| New `.srec` still starts at `0x08000000` | Built before the linker change | **Clean** build; verify `head -3 …srec` shows `S315 08020000` |

---

## Lessons learned (bugs we hit and fixed)

A short field log, so the next person doesn't re-derive these:

- **UART framing desync → `BAD LENGTH` flood.** A single stray byte ahead of the 4-byte
  length prefix shifts the whole stream by one byte; the firmware then slices the SREC
  *text* into garbage "lengths" forever. Always start from a clean port/reset.
- **`.symbolsrec` is not flashable.** It's a symbol table dump that happens to look
  S-record-ish. Only a real `.srec` (S0/S1/S2/S3) is firmware.
- **Master RX DLC parse.** In the current STM32H7 HAL, `FDCAN_RxHeaderTypeDef.DataLength`
  is already a **byte count**, not a `<<16` DLC code. An extra `>> 16` made every target
  reply read as 0 bytes → XCP connect "timed out" even though the target was answering.
  Fixed in [`blt_port.c`](1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/App/blt_port.c)
  (`HAL_FDCAN_RxFifo0Callback`).
- **Application link address.** Apps must be linked at `0x08020000` (above the 128 KB
  bootloader) **and** relocate VTOR. An app linked at `0x08000000` collides with the
  bootloader region and the program step is rejected — surfacing as a misleading
  "connect timeout."
- **Both FDCAN clocks differ but must both hit 500 kbit/s.** Master runs CAN from PLL1Q
  (50 MHz, via fractional-N — don't forget the `PLLFRACN`!); target from PLL2Q (80 MHz).
  An analyzer decoding the master's TX only proves the master's timing; the target still
  has to sample and ACK at the same bitrate.

---

## Limitations & future work

- **No authentication.** XCP seed/key is disabled on both ends
  (`BOOT_XCP_SEED_KEY_ENABLE = 0`). Re-enable it (and the master's
  `XcpComputeKeyFromSeed`) for any non-bench use.
- **Backdoor entry is manual.** To update a *running* app you currently must force the
  bootloader (hold PC13 + reset, or have no valid app). Add an app-commanded
  "reboot into bootloader" path (e.g. a shared-RAM flag or a CAN command) for true OTA.
- **Master auto-flashes on every received file.** There's no explicit "commit/confirm"
  handshake — any verified file triggers `UpdateFirmware`. Consider an explicit command.
- **Single, fixed timeouts.** 5 s per RX chunk on the master and ~5 s XCP connect; large
  or slow transfers may want tuning, plus progress reporting (the target's `EventsHook`
  is available but disabled).
- **No CRC on the USB transfer.** The master checks length only, not content integrity.
- **FreeRTOS port is `ARM_CM4F` on a Cortex-M7.** It works, but `ARM_CM7/r0p1` is the
  stricter-correct port; FPU context save is disabled.
- **Max image 440 KB** (RAM-disk limit). Larger images need a different buffering strategy.

---

## References

- **OpenBLT** — bootloader framework: <https://www.feaser.com/openblt/> (submodule: `1_Embedded/openblt/`)
- **LibMicroBLT** — XCP-on-CAN master library: <https://github.com/feaser/libmicroblt> (submodule: `1_Embedded/libmicroblt/`)
- **XCP** — the calibration/programming protocol used over CAN (ASAM MCD-1 XCP).
- Key source files:
  - Master receive/flash loop — [`Core/Src/main.c`](1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/Core/Src/main.c) (`FwUpdateTask`)
  - Master XCP-on-CAN port — [`App/blt_port.c`](1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/App/blt_port.c)
  - Target bootloader config — [`Boot/App/blt_conf.h`](1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Slave/Boot/App/blt_conf.h)
  - Target backdoor/LED hooks — [`Boot/App/hooks.c`](1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Slave/Boot/App/hooks.c)
  - Host tool — [`3_Python_Scripts/send_srec.py`](3_Python_Scripts/send_srec.py)
