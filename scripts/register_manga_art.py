"""Register the manga production set without changing any artwork pixels."""
import json
from math import ceil
from pathlib import Path
from statistics import mean
from PIL import Image
from register_cel_art import texture
from register_new_dogs import mouth_anchor

ROOT = Path(__file__).resolve().parents[1]
BASE = 'assets/manga/'
BREEDS = [('puppy','Puppy'),('shiba','Shiba Inu'),('golden','Golden Retriever')]
EXTRAS = [('dachshund','Dachshund'),('mini_collie','Miniature Collie'),('beagle','Beagle'),('corgi','Corgi'),('toy_poodle','Toy Poodle')]

def write(path, data):
    (ROOT/BASE/path).write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

def bounds(image, cell):
    x,y,right,bottom = cell
    mask = image.crop(cell).getchannel('A').point(lambda a:255 if a>=194 else 0)
    box = mask.getbbox()
    if box is None: raise ValueError(f'Empty artwork cell {cell}')
    l,t,r,b = box
    return [x+max(0,l-2),y+max(0,t-2),min(right-x,r+2)-max(0,l-2),min(bottom-y,b+2)-max(0,t-2)]

def grid(path, columns, rows, adaptive=False, ys=None):
    image=Image.open(ROOT/BASE/path).convert('RGBA')
    cuts=ys or [round(image.height*r/rows) for r in range(rows+1)]
    if adaptive:
        alpha=image.getchannel('A').point(lambda a:255 if a>=194 else 0)
        profile=[alpha.crop((0,y,image.width,y+1)).histogram()[255] for y in range(image.height)]
        for row in range(1,rows):
            expected=image.height*row/rows
            options=range(max(cuts[row-1]+1,int(expected-image.height*.055)),min(image.height,int(expected+image.height*.055)))
            cuts[row]=min(options,key=lambda y:(sum(profile[max(0,y-3):y+4]),abs(y-expected)))
    boxes=[bounds(image,(round(c*image.width/columns),cuts[r],round((c+1)*image.width/columns),cuts[r+1])) for r in range(rows) for c in range(columns)]
    return image,boxes

def atlas_texture(name, atlas, box, offset=0, padding=0):
    texture(ROOT/BASE/name,BASE+atlas,box,offset,padding)

def walk_data(image, poses):
    height=max(p[3] for p in poses)
    regions=[]; anchors=[]
    for x,y,w,h in poses:
        y=max(0,y+h-height)
        regions.append([x,y,w,height])
        # Track the torso, leaving alternating paws and the tail out of the anchor.
        mask=image.crop((x,y+int(height*.35),x+w,y+int(height*.65))).getchannel('A')
        samples=[px for py in range(mask.height) for px in range(w) if mask.getpixel((px,py))>=194]
        anchors.append(round(mean(samples),2) if samples else w/2)
    return {'regions':regions,'anchors':anchors,'height':float(height)}

def residents():
    result={}
    for name in ['nora','june','ben','leah','owen','ren','kai']:
        file='nora_smile_anime_greeting_v3.png' if name=='nora' else name+'_idle_sheet.png'
        atlas='characters/'+file
        image=Image.open(ROOT/BASE/atlas).convert('RGBA')
        columns=3 if name=='nora' else 2
        cw,ch=image.width//columns,image.height//2
        rows=[]; registration=[]; torso_rows=[]; torso_margins=[]
        for row in range(1 if name=='kai' else 2):
            local=[]
            for c in range(columns):
                x,y,w,h=bounds(image,(c*cw,row*ch,(c+1)*cw,(row+1)*ch))
                local.append([x-c*cw,y-row*ch,w,h])
            left=min(b[0] for b in local); top=min(b[1] for b in local)
            right=max(b[0]+b[2] for b in local); bottom=max(b[1]+b[3] for b in local)
            frames=[[c*cw+left,row*ch+top,right-left,bottom-top] for c in range(columns)]
            centers=[]
            for c in range(columns):
                samples=[]
                for y in range(int(ch*.14),int(ch*.28)):
                    for x in range(int(cw*.25),int(cw*.72)):
                        r,g,b,a=image.getpixel((c*cw+x,row*ch+y))
                        if a>=194 and r>150 and g>85 and b>45 and r>g*1.1 and g>b*1.05 and r-b>35: samples.append(x)
                centers.append(mean(samples) if samples else cw/2)
            offsets=[round(max(centers)-v,2) for v in centers]; padding=ceil(max(offsets))
            rows.append(frames); registration.append({'offsets':offsets,'padding':padding})
            atlas_texture(f'characters/{name}_anime_{row}.tres',atlas,frames[0],offsets[0],padding)
            crop_bottom=top+round((bottom-top)*(.65 if name=='nora' else .74))
            upper=[bounds(image,(c*cw,row*ch,(c+1)*cw,row*ch+crop_bottom)) for c in range(columns)]
            l=min(b[0]-c*cw+offsets[c] for c,b in enumerate(upper))
            r=max(b[0]-c*cw+b[2]+offsets[c] for c,b in enumerate(upper))
            t=min(b[1] for b in upper); extent=[ceil(r-l),row*ch+crop_bottom-t]
            torso_rows.append(upper)
            torso_margins.append([[round(b[0]-c*cw+offsets[c]-l,2),b[1]-t,extent[0]-b[2],extent[1]-b[3]] for c,b in enumerate(upper)])
        result[name]={'atlas':BASE+atlas,'rows':rows,'registration':registration,'torso_rows':torso_rows,'torso_margins':torso_margins}
    write('characters/anime_frames.json',result)

def dogs():
    walks={}; bare_walks={}; tricks={}; bare_tricks={}; sizes={}
    for dressed in [False,True]:
        for stem,breed in BREEDS:
            suffix='' if dressed else '_bare'
            for pose in ['', '_sleep']:
                atlas=f'puppies/{stem}{suffix}{pose}_anime.png'
                image,boxes=grid(atlas,1,1)
                atlas_texture(atlas.replace('.png','.tres'),atlas,boxes[0])
                if dressed and pose: sizes[breed]=boxes[0][2:]
            image,boxes=grid(f'puppies/{stem}{suffix}_walk_anime.png',4,2)
            (walks if dressed else bare_walks)[breed]=walk_data(image,boxes)
            atlas=f'puppies/{stem}{suffix}_tricks_anime.png'
            image,boxes=grid(atlas,3,4)
            (tricks if dressed else bare_tricks)[breed]={'atlas':BASE+atlas,'height':boxes[0][3],'rows':{command:boxes[r*3:r*3+3] for r,command in enumerate(['Paw','Spin','Bow','Roll Over'])}}
    write('puppies/walk_anime_frames.json',walks)
    write('puppies/trick_anime_frames.json',tricks)
    write('puppies/bare_anime_frames.json',{'walks':bare_walks,'tricks':bare_tricks})
    write('puppies/sleep_anime_sizes.json',sizes)
    extras={}
    for stem,breed in EXTRAS:
        item={}
        for dressed in [False,True]:
            suffix='' if dressed else '_bare'
            atlas=f'puppies/{stem}{suffix}_anime.png'
            image,p=grid(atlas,4,5,True)
            trick={'Paw':[p[12],p[13],p[12]],'Spin':[p[0],p[14],p[0]],'Bow':[p[0],p[16],p[0]],'Roll Over':[p[0],p[15],p[0]]}
            item['dressed' if dressed else 'bare']={'atlas':BASE+atlas,'walk':walk_data(image,p[4:12]),'tricks':{'atlas':BASE+atlas,'height':p[0][3],'rows':trick},'moments':dict(zip(['Bow','Sniff','Tilt','Stretch','Greet','Tug'],[p[16],p[18],p[2],p[17],p[3],p[19]])),'mouth':mouth_anchor(image,p[19])}
            atlas_texture(atlas.replace('.png','.tres'),atlas,p[0])
            sleep=f'puppies/{stem}{suffix}_sleep_pose_anime.png'
            box=grid(sleep,1,1)[1][0] if (ROOT/BASE/sleep).exists() else p[1]
            atlas_texture(f'puppies/{stem}{suffix}_sleep_anime.tres',sleep if (ROOT/BASE/sleep).exists() else atlas,box)
        extras[breed]=item
    write('puppies/extra_dogs_anime_frames.json',extras)
    reactions={}
    for dressed in [False,True]:
        atlas='puppies/reactions'+('' if dressed else '_bare')+'_anime.png'
        image,p=grid(atlas,4,3,True)
        reactions['dressed' if dressed else 'bare']={'atlas':BASE+atlas,'breeds':{breed:dict(zip(['Tilt','Stretch','Greet','Tug'],p[r*4:r*4+4])) for r,(_,breed) in enumerate(BREEDS)},'mouths':{breed:mouth_anchor(image,p[r*4+3]) for r,(_,breed) in enumerate(BREEDS)}}
    write('puppies/reactions_anime_frames.json',reactions)

def moments_and_goods():
    result={}
    for group,atlas,cols,rows,names in [
        ('residents','characters/residents_moments_anime.png',2,2,['Ben','Nora','Kai','Ren']),
        ('dogs','puppies/dogs_moments_anime.png',2,3,[b+':'+p for _,b in BREEDS for p in ['Bow','Sniff']]),
        ('bare_dogs','puppies/dogs_bare_moments_anime.png',2,3,[b+':'+p for _,b in BREEDS for p in ['Bow','Sniff']]),
        ('props','goods/moment_keepsakes_anime.png',3,1,['Shell','Glass','Star'])]:
        image,boxes=grid(atlas,cols,rows,ys=[0,462,957,1536] if group in ['dogs','bare_dogs'] else None)
        result[group]={'atlas':BASE+atlas,'frames':dict(zip(names,boxes))}
    write('moments_anime_frames.json',result)
    goods={}
    for atlas,cols,rows,names in [
        ('goods/goods_anime.png',3,2,['Treat','TrainingTreat','Toy','Brush','Shampoo','Bed']),
        ('goods/expanded_goods_anime.png',3,3,['PuppyMeal','AdultMeal','PicnicPack','CelebrationTreat','PlushToy','TugRope','CloudBed','CoolingMat','Blanket'])]:
        boxes=grid(atlas,cols,rows)[1]
        goods.update(dict(zip(names,boxes)))
    write('goods/frames.json',goods)

if __name__=='__main__':
    residents(); dogs(); moments_and_goods()
    print('Manga residents, dogs, story props and goods registered.')
