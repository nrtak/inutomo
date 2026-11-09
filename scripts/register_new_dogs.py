"""Register dog atlas regions and ground anchors without changing artwork."""
from pathlib import Path
import json
from statistics import mean
from PIL import Image
from register_cel_art import texture, subject_bounds

ROOT = Path(__file__).resolve().parents[1]

def regions(path, rows):
    image = Image.open(ROOT / path).convert('RGBA')
    alpha = image.getchannel('A').point(lambda a: 255 if a >= 194 else 0)
    profile = [sum(alpha.crop((0, y, image.width, y+1)).histogram()[255:]) for y in range(image.height)]
    cuts = [0]
    for row in range(1, rows):
        expected = image.height*row/rows
        window = range(max(cuts[-1]+1,int(expected-image.height*.055)),min(image.height,int(expected+image.height*.055)))
        cut = min(window,key=lambda y:(sum(profile[max(0,y-3):y+4]),abs(y-expected)))
        cuts.append(cut)
    cuts.append(image.height)
    result = []
    for row in range(rows):
        for col in range(4):
            x0,x1 = round(col*image.width/4),round((col+1)*image.width/4)
            y0,y1 = cuts[row],cuts[row+1]
            left,top,right,bottom = subject_bounds(image,(x0,y0,x1,y1),horizontal_overflow=round((x1-x0)*.15))
            start_x,start_y = x0+left,y0+top
            end_x,end_y = x0+right,y0+bottom
            result.append([start_x,start_y,end_x-start_x,end_y-start_y])
    return image,result

def register_breed(stem, breed):
    result = {}
    for dressed in [False,True]:
        suffix = '' if dressed else '_bare'
        atlas = f'assets/puppies/{stem}{suffix}_anime.png'
        image,poses = regions(atlas,5)
        # All eight frames share a height and ground baseline; torso pixels anchor x.
        height = max(box[3] for box in poses[4:12])
        walk,anchors = [],[]
        for x,y,w,h in poses[4:12]:
            box = [x,y+h-height,w,height]
            walk.append(box)
            samples = [px for py in range(int(height*.35),int(height*.65)) for px in range(w) if image.getpixel((x+px,box[1]+py))[3]>=194]
            anchors.append(round(mean(samples),2) if samples else w/2)
        tricks = {'Paw':[poses[12],poses[13],poses[12]],'Spin':[poses[0],poses[14],poses[0]],'Bow':[poses[0],poses[16],poses[0]],'Roll Over':[poses[0],poses[15],poses[0]]}
        moments = {'Bow':poses[16],'Sniff':poses[18],'Tilt':poses[2],'Stretch':poses[17],'Greet':poses[3],'Tug':poses[19]}
        result['dressed' if dressed else 'bare'] = {'atlas':atlas,'walk':{'regions':walk,'anchors':anchors,'height':height},'tricks':{'atlas':atlas,'height':poses[0][3],'rows':tricks},'moments':moments,'mouth':mouth_anchor(image,poses[19])}
        texture(ROOT/f'assets/puppies/{stem}{suffix}_anime.tres',atlas,poses[0])
        sleep_atlas = f'assets/puppies/{stem}{suffix}_sleep_pose_anime.png'
        if (ROOT/sleep_atlas).exists():
            sleeping = Image.open(ROOT/sleep_atlas).convert('RGBA')
            l,t,r,b = subject_bounds(sleeping,(0,0,sleeping.width,sleeping.height))
            texture(ROOT/f'assets/puppies/{stem}{suffix}_sleep_anime.tres',sleep_atlas,[l,t,r-l,b-t])
        else:
            texture(ROOT/f'assets/puppies/{stem}{suffix}_sleep_anime.tres',atlas,poses[1])
    return result

def mouth_anchor(image, bounds):
    x0,y0,w,h = bounds
    samples = []
    # The lower muzzle contains the tongue; pink upright ears are not a grip point.
    for y in range(round(h*.55),h):
        for x in range(w):
            r,g,b,a = image.getpixel((x0+x,y0+y))
            if a>=194 and r>120 and r>g*1.35 and r>b*1.15 and b>g*.8:
                samples.append((x,y))
    return [round(mean(p[axis] for p in samples),2) for axis in range(2)] if samples else [w*.6,h*.65]

def main():
    breeds = {breed:register_breed(stem,breed) for stem,breed in [('dachshund','Dachshund'),('mini_collie','Miniature Collie'),('beagle','Beagle'),('corgi','Corgi'),('toy_poodle','Toy Poodle')]}
    (ROOT/'assets/puppies/extra_dogs_anime_frames.json').write_text(json.dumps(breeds,indent=2)+'\n',encoding='utf-8')
    reactions = {}
    for dressed in [False,True]:
        atlas = 'assets/puppies/reactions'+('' if dressed else '_bare')+'_anime.png'
        if not (ROOT/atlas).exists(): continue
        image,poses = regions(atlas,3)
        reactions['dressed' if dressed else 'bare'] = {'atlas':atlas,'breeds':{breed:{pose:poses[row*4+col] for col,pose in enumerate(['Tilt','Stretch','Greet','Tug'])} for row,breed in enumerate(['Puppy','Shiba Inu','Golden Retriever'])},'mouths':{breed:mouth_anchor(image,poses[row*4+3]) for row,breed in enumerate(['Puppy','Shiba Inu','Golden Retriever'])}}
    (ROOT/'assets/puppies/reactions_anime_frames.json').write_text(json.dumps(reactions,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__': main()
