"""Register the detailed anime sprites without modifying source images."""
import json
from pathlib import Path
from math import ceil
from PIL import Image
from register_cel_art import bounds, texture

ROOT = Path(__file__).resolve().parents[1]


def write_json(path, value):
    (ROOT / path).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def residents():
    result = {}
    for name in ['nora', 'june', 'ben', 'leah', 'owen', 'ren', 'kai']:
        atlas = f'assets/characters/{name}_anime_greeting_v2.png' if name == 'nora' else f'assets/characters/{name}_idle_sheet.png'
        image = Image.open(ROOT / atlas).convert('RGBA')
        columns = 3 if name == 'nora' else 2
        width, height = image.width // columns, image.height // 2
        rows, registrations, torso_rows, torso_margins = [], [], [], []
        for row in range(1 if name == 'kai' else 2):
            boxes = [bounds(image, (c*width, row*height, (c+1)*width, (row+1)*height)) for c in range(columns)]
            union = [min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)]
            frames = [[c*width+union[0], row*height+union[1], union[2]-union[0], union[3]-union[1]] for c in range(columns)]
            rows.append(frames)
            centers = []
            for column in range(columns):
                cell = image.crop((column*width, row*height, (column+1)*width, (row+1)*height))
                samples = []
                # Sample the upper face, excluding a raised hand or bare arm.
                for y in range(int(height*.14), int(height*.28)):
                    for x in range(int(width*.25), int(width*.72)):
                        r,g,b,a = cell.getpixel((x,y))
                        if a >= 128 and r > 150 and g > 85 and b > 45 and r > g*1.1 and g > b*1.05 and r-b > 35:
                            samples.append(x)
                centers.append(sum(samples)/len(samples) if samples else width/2)
            offsets = [round(max(centers)-center,2) for center in centers]
            padding = ceil(max(offsets))
            registrations.append({'offsets':offsets, 'padding':padding})
            texture(ROOT/f'assets/characters/{name}_anime_{row}.tres', atlas, frames[0], offsets[0], padding)
            # Register the upper body independently: lower arms and hips no longer
            # force a small face or leave unused transparent space beside it.
            bottom = union[1] + round((union[3]-union[1])*(.65 if name == 'nora' else .74))
            upper = [bounds(image, (c*width, row*height, (c+1)*width, row*height+bottom), 2) for c in range(columns)]
            left = min(box[0]+offsets[c] for c,box in enumerate(upper))
            right = max(box[2]+offsets[c] for c,box in enumerate(upper))
            top = min(box[1] for box in upper)
            extent = [ceil(right-left), bottom-top]
            torso_rows.append([[c*width+b[0],row*height+b[1],b[2]-b[0],b[3]-b[1]] for c,b in enumerate(upper)])
            torso_margins.append([[round(b[0]+offsets[c]-left,2),b[1]-top,extent[0]-(b[2]-b[0]),extent[1]-(b[3]-b[1])] for c,b in enumerate(upper)])
        result[name] = {'atlas':atlas, 'rows':rows, 'registration':registrations,
                        'torso_rows':torso_rows, 'torso_margins':torso_margins}
    write_json('assets/characters/anime_frames.json', result)


def dogs():
    sizes = {}
    for name, breed in [('puppy','Puppy'),('shiba','Shiba Inu'),('golden','Golden Retriever')]:
        for sleep in [False, True]:
            stem = name + ('_sleep' if sleep else '')
            atlas = f'assets/puppies/{stem}_anime.png'
            image = Image.open(ROOT/atlas).convert('RGBA')
            left,top,right,bottom = bounds(image, (0,0,image.width,image.height), 2)
            region = (left,top,right-left,bottom-top)
            texture(ROOT/f'assets/puppies/{stem}_anime.tres', atlas, region)
            if sleep:
                sizes[breed] = list(region[2:])
    write_json('assets/puppies/sleep_anime_sizes.json', sizes)
    # Keep the original, tested torso anchors and ground registration.
    walk = {
        'Puppy': {
            'regions':[[21,75,402,337],[452,75,414,338],[895,75,414,338],[1337,75,416,338],[17,496,406,338],[460,496,407,337],[894,495,416,338],[1345,495,409,338]],
            'anchors':[207.44,223.14,225.04,223.87,216.5,213.07,226.99,212.49], 'height':338.0},
        'Shiba Inu': {
            'regions':[[30,35,413,383],[443,35,443,383],[913,35,416,383],[1341,37,430,381],[34,474,409,383],[443,474,443,382],[903,474,426,382],[1345,475,425,382]],
            'anchors':[207.9,233.16,204.3,221.75,202.66,235.88,216.97,219.26], 'height':382.5},
        'Golden Retriever': {
            'regions':[[23,76,409,322],[462,76,406,324],[903,76,408,328],[1342,77,411,320],[21,503,407,323],[459,503,409,326],[901,502,410,331],[1347,503,412,323]],
            'anchors':[205.78,207.29,207.41,210.94,207.99,211.44,209.41,208.26], 'height':323.5}
    }
    write_json('assets/puppies/walk_anime_frames.json', walk)
    tricks = {}
    for name,breed in [('puppy','Puppy'),('shiba','Shiba Inu'),('golden','Golden Retriever')]:
        atlas = f'assets/puppies/{name}_tricks_anime.png'
        image = Image.open(ROOT/atlas).convert('RGBA')
        width,height = image.width//3,image.height//4
        rows = {}
        for row,command in enumerate(['Paw','Spin','Bow','Roll Over']):
            frames = []
            for column in range(3):
                x,y = column*width,row*height
                l,t,r,b = bounds(image,(x,y,x+width,y+height),2)
                frames.append([x+l,y+t,r-l,b-t])
            rows[command] = frames
        tricks[breed] = {'atlas':atlas, 'height':rows['Paw'][0][3], 'rows':rows}
    write_json('assets/puppies/trick_anime_frames.json', tricks)


if __name__ == '__main__':
    residents()
    dogs()
    print('Detailed anime sprite registrations generated.')
