#!/usr/bin/env python3
"""Synthesises Bit's own sounds (plain sine blips) into assets/sounds/. Run again to regenerate."""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(notes):
    """notes: [(frequency Hz or 0 for rest, seconds)] -> 16-bit samples with a soft attack and release."""
    out = []
    for hz, secs in notes:
        n = int(RATE * secs)
        for i in range(n):
            env = min(1, i / 200, (n - i) / 400) if hz else 0
            out.append(int(9000 * env * math.sin(2 * math.pi * hz * i / RATE)))
    return out


SOUNDS = {
    "ask": [(660, 0.09), (880, 0.14)],
    "done": [(523, 0.08), (659, 0.08), (784, 0.16)],
    "oops": [(330, 0.12), (247, 0.2)],
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, notes in SOUNDS.items():
        with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(struct.pack("<h", s) for s in tone(notes)))
        print(f"wrote {name}.wav")
