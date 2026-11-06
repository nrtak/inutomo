"""Register layered moment artwork and accessory-free animation alternatives."""
import json
from pathlib import Path
from statistics import median
from PIL import Image
from register_cel_art import bounds, texture

ROOT = Path(__file__).resolve().parents[1]

def cells(path, columns, rows):
    image = Image.open(ROOT / path).convert('RGBA')
    width, height = image.width // columns, image.height // rows
    frames = []
    for row in range(rows):
        for col in range(columns):
            x, y = col * width, row * height
            left, top, right, bottom = bounds(image, (x, y, x+width, y+height), 2)
            frames.append([x+left, y+top, right-left, bottom-top])
    return frames

def moment_dogs(path):
    image = Image.open(ROOT/path).convert('RGBA')
    # The six illustrations use optical spacing rather than exact equal cells.
    xs = [0,530,image.width]
    ys = [0,462,957,image.height]
    frames = []
    for row in range(3):
        for col in range(2):
            x,y = xs[col],ys[row]
            l,t,r,b = bounds(image,(x,y,xs[col+1],ys[row+1]),2)
            frames.append([x+l,y+t,r-l,b-t])
    return frames

def register():
    result = {}
    entries = [
        ('residents','assets/characters/residents_moments_anime.png',2,2,['Ben','Nora','Kai','Ren']),
        ('dogs','assets/puppies/dogs_moments_anime.png',2,3,[b+':'+p for b in ['Puppy','Shiba Inu','Golden Retriever'] for p in ['Bow','Sniff']]),
        ('bare_dogs','assets/puppies/dogs_bare_moments_anime.png',2,3,[b+':'+p for b in ['Puppy','Shiba Inu','Golden Retriever'] for p in ['Bow','Sniff']]),
        ('props','assets/goods/moment_keepsakes_anime.png',3,1,['Shell','Glass','Star'])]
    for group,path,columns,rows,names in entries:
        frames = moment_dogs(path) if group in ['dogs','bare_dogs'] else cells(path,columns,rows)
        result[group] = {'atlas':path,'frames':dict(zip(names,frames))}
    (ROOT/'assets/moments_anime_frames.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    old_walks = json.loads((ROOT/'assets/puppies/walk_anime_frames.json').read_text())
    bare = {'walks':{},'tricks':{}}
    for stem,breed in [('puppy','Puppy'),('shiba','Shiba Inu'),('golden','Golden Retriever')]:
        for pose in ['', '_sleep']:
            atlas = f'assets/puppies/{stem}_bare{pose}_anime.png'
            region = cells(atlas,1,1)[0]
            texture(ROOT/atlas.replace('.png','.tres'),atlas,region)
        walk_atlas = f'assets/puppies/{stem}_bare_walk_anime.png'
        frames = cells(walk_atlas,4,2)
        anchors = [round(old_walks[breed]['regions'][i][0]+old_walks[breed]['anchors'][i]-box[0],2) for i,box in enumerate(frames)]
        bare['walks'][breed] = {'regions':frames,'anchors':anchors,'height':median(f[3] for f in frames)}
        trick_atlas = f'assets/puppies/{stem}_bare_tricks_anime.png'
        frames = cells(trick_atlas,3,4)
        bare['tricks'][breed] = {'atlas':trick_atlas,'height':frames[0][3],'rows':{name:frames[i*3:i*3+3] for i,name in enumerate(['Paw','Spin','Bow','Roll Over'])}}
    (ROOT/'assets/puppies/bare_anime_frames.json').write_text(json.dumps(bare,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    register()
    print('Moment and bare-neck artwork registered without altering image pixels.')
