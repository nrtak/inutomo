"""Register sprite regions without changing any source artwork."""
import json
from pathlib import Path
from statistics import median
from math import ceil

from PIL import Image
from dog_atlas_bounds import subject_bounds

ROOT = Path(__file__).resolve().parents[1]


def bounds(image, cell, padding=3):
    alpha = image.crop(cell).getchannel('A')
    box = alpha.point(lambda value: 255 if value >= 96 else 0).getbbox()
    if box is None:
        raise ValueError(f'Empty sprite cell: {cell}')
    return (max(0, box[0]-padding), max(0, box[1]-padding),
            min(alpha.width, box[2]+padding), min(alpha.height, box[3]+padding))


def texture(path, atlas, region, offset=0, padding=0):
    x, y, width, height = region
    path.write_text(
        '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Texture2D" path="res://{atlas}" id="1"]\n\n'
        '[resource]\natlas = ExtResource("1")\n'
        f'region = Rect2({x}, {y}, {width}, {height})\n'
        f'margin = Rect2({offset}, 0, {padding}, 0)\nfilter_clip = true\n',
        encoding='utf-8')


def residents():
    result = {}
    texture(ROOT / 'assets/characters/kai_cel_0.tres', 'assets/characters/kai_cel_sheet.png', (198,2,502,885))
    for name in ['nora', 'june', 'ben', 'leah', 'owen', 'ren']:
        atlas = f'assets/characters/{name}_cel_sheet.png'
        image = Image.open(ROOT / atlas).convert('RGBA')
        columns = 3 if name == 'nora' else 2
        width, height = image.width // columns, image.height // 2
        rows, registrations = [], []
        for row in range(2):
            boxes = [bounds(image, (column*width, row*height,
                                    (column+1)*width, (row+1)*height))
                     for column in range(columns)]
            union = [min(box[0] for box in boxes), min(box[1] for box in boxes),
                     max(box[2] for box in boxes), max(box[3] for box in boxes)]
            frames = [[column*width+union[0], row*height+union[1],
                       union[2]-union[0], union[3]-union[1]]
                      for column in range(columns)]
            rows.append(frames)
            face_centers = []
            for column in range(columns):
                pixels = image.crop((column*width, row*height,
                                     (column+1)*width, (row+1)*height))
                samples = []
                for y in range(int(height*.17), int(height*.40)):
                    for x in range(int(width*.15), int(width*.77)):
                        r,g,b,a = pixels.getpixel((x,y))
                        if a >= 128 and r > 150 and g > 85 and b > 45 and r > g*1.1 and g > b*1.05 and r-b > 35:
                            samples.append(x)
                face_centers.append(sum(samples)/len(samples) if samples else width/2)
            offsets = [round(max(face_centers)-center,2) for center in face_centers]
            padding = ceil(max(offsets))
            registrations.append({'offsets': offsets, 'padding': padding})
            texture(ROOT / f'assets/characters/{name}_cel_{row}.tres', atlas, frames[0], offsets[0], padding)
        result[name] = {'atlas': atlas, 'rows': rows, 'registration': registrations}
    (ROOT / 'assets/characters/cel_frames.json').write_text(
        json.dumps(result, indent=2)+'\n', encoding='utf-8')


def dogs():
    atlas = 'assets/puppies/beach_cel_dogs.png'
    awake = [(64,146,361,444), (516,53,425,538), (999,39,474,558)]
    asleep = [(51,727,396,234), (505,703,429,258), (989,688,519,276)]
    for column, name in enumerate(['puppy', 'shiba', 'golden']):
        texture(ROOT / f'assets/puppies/{name}_cel.tres', atlas, awake[column])
        texture(ROOT / f'assets/puppies/{name}_sleep_cel.tres', atlas, asleep[column])
    result = {}
    for name, breed in [('puppy','Puppy'), ('shiba','Shiba Inu'), ('golden','Golden Retriever')]:
        image = Image.open(ROOT / f'assets/puppies/{name}_walk_cel.png').convert('RGBA')
        width, height = image.width // 4, image.height // 2
        regions, anchors, heights = [], [], []
        for index in range(8):
            column, row = index % 4, index // 4
            cell = (column*width, row*height, (column+1)*width, (row+1)*height)
            box = bounds(image, cell, 2)
            region = [cell[0]+box[0], cell[1]+box[1], box[2]-box[0], box[3]-box[1]]
            regions.append(region)
            heights.append(region[3])
            # Register the torso, rather than the alternating paws or tail tip.
            mask = image.crop((region[0], region[1]+int(region[3]*0.30),
                               region[0]+region[2], region[1]+int(region[3]*0.62))).getchannel('A')
            samples = [x for y in range(mask.height) for x in range(mask.width)
                       if mask.getpixel((x,y)) >= 96]
            anchors.append(round(sum(samples)/len(samples), 2) if samples else region[2]/2)
        result[breed] = {'regions': regions, 'anchors': anchors, 'height': median(heights)}
    (ROOT / 'assets/puppies/walk_cel_frames.json').write_text(
        json.dumps(result, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    residents()
    dogs()
    print('Cel sprite registrations generated.')
