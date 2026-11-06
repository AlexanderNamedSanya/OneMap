"""Generate OneMap's original anti-aliased ring as a power-of-two RGBA DDS."""
from pathlib import Path
import math
import struct

root = Path(__file__).resolve().parents[1]
size = 128
header = [124, 0x100F, size, size, size * 4, 0, 0] + [0] * 11
header += [32, 0x41, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000]
header += [0x1000, 0, 0, 0, 0]
pixels = bytearray()
for y in range(size):
    for x in range(size):
        radius = math.hypot(x + 0.5 - size / 2, y + 0.5 - size / 2)
        alpha = round(255 * math.exp(-0.5 * ((radius - 53) / 3.0) ** 2))
        pixels.extend((255, 255, 255, alpha))
target = root / "OneMap/art/wave.dds"
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(b"DDS " + struct.pack("<31I", *header) + pixels)
print(f"Generated {target.name}: {size}x{size}, {target.stat().st_size} bytes")
