"""Reduce decoding to ~24 fps at playback x7, preserving RGBA frames and duration.

Run once on the original clip: python optimize_meteor_clip.py INPUT OUTPUT
Requires Pillow. The optimized asset's impact is frame 18 (source frame 120).
"""
import sys
from pathlib import Path
from PIL import Image, ImageChops

source, destination = map(Path, sys.argv[1:])
frames, durations = [], []
with Image.open(source) as original:
    assert original.n_frames >= 120, 'Input must be the original full-frame clip'
    size = original.size
    for index in range(original.n_frames):
        original.seek(index)
        original.load()
        if index % 7 == 0:
            frames.append(original.convert('RGBA').copy())
            durations.append(0)
        durations[-1] += original.info['duration']
frames[0].save(destination, format='WEBP', save_all=True,
               append_images=frames[1:], duration=durations, loop=0,
               lossless=True, method=4, exact=True)
with Image.open(destination) as result:
    assert result.size == size and result.n_frames == len(frames)
    total = 0
    for index, expected in enumerate(frames):
        result.seek(index)
        result.load()
        actual = result.convert('RGBA')
        # Transparent RGB values do not affect rendering; compare visible pixels.
        assert ImageChops.difference(actual.getchannel('A'), expected.getchannel('A')).getbbox() is None
        black = Image.new('RGBA', size, (0, 0, 0, 255))
        assert ImageChops.difference(Image.alpha_composite(black, actual).convert('RGB'), Image.alpha_composite(black, expected).convert('RGB')).getbbox() is None
        total += result.info['duration']
    assert total == sum(durations)
print(f'{len(frames)} frames, {total} ms; {source.stat().st_size} -> {destination.stat().st_size} bytes')
