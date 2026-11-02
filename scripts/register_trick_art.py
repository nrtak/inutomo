"""Register transparent trick atlas frames without altering source artwork."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parent.parent
result = {}
for breed, name in [('Puppy','puppy'),('Shiba Inu','shiba'),('Golden Retriever','golden')]:
    path = f'assets/puppies/{name}_tricks_cel.png'
    image = Image.open(ROOT / path).convert('RGBA')
    width, height = image.width // 3, image.height // 4
    rows = {}
    for row, command in enumerate(['Paw','Spin','Bow','Roll Over']):
        frames = []
        for column in range(3):
            x,y = column*width,row*height
            alpha = image.getchannel('A').crop((x,y,x+width,y+height))
            box = alpha.point(lambda a: 255 if a >= 96 else 0).getbbox()
            assert box is not None, (breed,command,column)
            left,top,right,bottom = box
            left,top = max(0,left-2),max(0,top-2)
            right,bottom = min(width,right+2),min(height,bottom+2)
            frames.append([x+left,y+top,right-left,bottom-top])
        rows[command] = frames
    result[breed] = {'atlas':path,'height':rows['Paw'][0][3],'rows':rows}
(ROOT/'assets/puppies/trick_cel_frames.json').write_text(json.dumps(result,indent=2)+'\n')
print('Trick atlas registrations generated.')
