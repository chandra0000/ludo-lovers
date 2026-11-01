#!/usr/bin/env python3
"""Generate a phone-sized, compressed WebP from the approved board artwork.

The original PNG stays in source control as the lossless design master. Only the
generated WebP is declared as a Flutter runtime asset.
"""
from pathlib import Path
from PIL import Image, ImageOps
import sys

SOURCE = Path("assets/images/ludo_board_glass.png")
OUTPUT = Path("assets/images/ludo_board_glass.webp")
MAX_EDGE = 1440
TARGET_BYTES = 300 * 1024
QUALITIES = (90, 86, 82, 78, 74)


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"Missing approved source artwork: {SOURCE}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    original_bytes = SOURCE.stat().st_size

    with Image.open(SOURCE) as source:
        image = ImageOps.exif_transpose(source)
        original_size = image.size
        image.thumbnail((MAX_EDGE, MAX_EDGE), Image.Resampling.LANCZOS)

        # Preserve transparency if the supplied board artwork contains alpha.
        has_alpha = "A" in image.getbands() or "transparency" in image.info
        image = image.convert("RGBA" if has_alpha else "RGB")

        chosen_quality = QUALITIES[-1]
        for quality in QUALITIES:
            image.save(
                OUTPUT,
                format="WEBP",
                quality=quality,
                method=6,
                exact=has_alpha,
            )
            chosen_quality = quality
            if OUTPUT.stat().st_size <= TARGET_BYTES:
                break

    with Image.open(OUTPUT) as optimized:
        optimized.verify()
    with Image.open(OUTPUT) as optimized:
        if optimized.format != "WEBP":
            raise SystemExit("Generated board asset is not WebP")
        if max(optimized.size) > MAX_EDGE:
            raise SystemExit(f"Unexpected output dimensions: {optimized.size}")

    output_bytes = OUTPUT.stat().st_size
    reduction = (1 - output_bytes / original_bytes) * 100
    print(f"Board source: {original_size[0]}x{original_size[1]}, {original_bytes:,} bytes")
    print(f"Board output: {image.width}x{image.height}, {output_bytes:,} bytes")
    print(f"WebP quality: {chosen_quality}; size reduction: {reduction:.1f}%")
    if output_bytes > TARGET_BYTES:
        raise SystemExit(
            "Optimized board exceeds the 300 KB runtime budget; "
            "inspect the source artwork/quality settings instead of "
            "shipping an asset that fails the Flutter asset test."
        )


if __name__ == "__main__":
    main()
