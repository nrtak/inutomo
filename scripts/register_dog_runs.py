"""Measure run-sheet frames and torso anchors; preserve the generated source pixels."""
import json
from register_manga_art import ROOT, BASE, BREEDS, EXTRAS, grid, walk_data


def main():
    result = {}
    for stem, breed in BREEDS + EXTRAS:
        path = f'puppies/{stem}_run_angles.png'
        image, boxes = grid(path, 4, 4)
        spec = {'atlas': BASE + path}
        for outfit, offset in [('bare', 0), ('dressed', 8)]:
            frames = boxes[offset:offset+8]
            # Both views use one common height, so turning never changes body size.
            measured = walk_data(image, frames)
            spec[outfit] = {}
            for angle, first in [('toward', 0), ('away', 4)]:
                spec[outfit][angle] = {
                    'regions': measured['regions'][first:first+4],
                    'anchors': measured['anchors'][first:first+4],
                    'height': measured['height'],
                }
        result[breed] = spec
    target = ROOT / BASE / 'puppies/run_angles_frames.json'
    target.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    manifest_path = ROOT / BASE / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    known = {entry['production'] for entry in manifest['assets']}
    for stem, _ in BREEDS + EXTRAS:
        production = f'{BASE}puppies/{stem}_run_angles.png'
        if production not in known:
            manifest['assets'].append({'source': f'{BASE}puppies/{stem}_bare_anime.png', 'production': production})
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Registered {len(result)} dog run sheets with bare and purchased-outfit views.')


if __name__ == '__main__':
    main()
