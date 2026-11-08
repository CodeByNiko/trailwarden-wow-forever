"""Inspect the real frame layout recorded by tests; this is not a WoW screenshot."""
import json
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[1]
font_path='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
version=re.search(r'## Version: (.+)',(root/'Wayfinder/Wayfinder.toc').read_text()).group(1)
for subject in ('nightelf','dwarf','settings','empty'):
    data=json.loads((root/f'tests/ui-{subject}.json').read_text())
    image=Image.new('RGBA',(700,780),(15,23,32,255));draw=ImageDraw.Draw(image)
    label=dict(nightelf='TELDRASSIL',dwarf='DUSKWOOD',settings='PREFERENCES',empty='PLANNED STEPS')[subject]
    draw.text((28,20),f'WAYFINDER {version}  /  {label}',font=ImageFont.truetype(font_path,18),fill='#e4eced')
    coords={};visible={}
    def color(values,default):
        return tuple(round(v*255) for v in values[:3])+(round(values[3]*255) if len(values)>3 else 255,) if values else default
    for index,node in enumerate(data,1):
        parent=node['parent'];name=node['name']
        if name=='UIParent': coords[index]=(0,0,1920,1080);visible[index]=True;continue
        if name=='WayfinderMainFrame': box=(28,66,node['w'],node['h']);show=node['shown']
        elif name=='WayfinderNavigatorFrame': box=(468,66,node['w'],node['h']);show=node['shown']
        else:
            px,py,pw,ph=coords.get(parent,(0,0,0,0));w,h=node['w'],node['h'];font=ImageFont.truetype(font_path,int(node['font']))
            if node['kind']=='font': w=w or int(font.getlength(node['text'].split('\n')[0]))+2;h=h or int(node['font']*1.35)
            else: w=w or pw;h=h or ph
            anchor=node['anchor'];x,y=node['x'],node['y']
            if 'RIGHT' in anchor: x+=pw-w
            elif 'LEFT' not in anchor: x+=(pw-w)/2
            if 'BOTTOM' in anchor: y=ph-h-y
            elif 'TOP' in anchor: y=-y
            else: y=(ph-h)/2-y
            box=(px+x,py+y,w,h);show=visible.get(parent,False) and node['shown']
        coords[index]=box;visible[index]=show
        if not show: continue
        x,y,w,h=map(round,box)
        if node['bg'] and node['kind']!='font':
            draw.rectangle((x,y,x+w,y+h),fill=color(node['bg'],(20,35,44,255)),outline=(41,64,78,255) if h>2 else None)
        if node['kind']=='font' and node['text']:
            font=ImageFont.truetype(font_path,int(node['font']));lines=[]
            for line in node['text'].split('\n'):
                words=line.split();current=''
                for word in words:
                    value=(current+' '+word).strip()
                    if current and font.getlength(value)>w: lines.append(current);current=word
                    else:current=value
                lines.append(current)
            tile=Image.new('RGBA',(max(1,w),max(1,h)),(0,0,0,0));td=ImageDraw.Draw(tile)
            for i,line in enumerate(lines): td.text((0,i*int(node['font']*1.25)-2),line,font=font,fill=color(node['color'],(235,240,240,255)))
            image.alpha_composite(tile,(x,y))
        if node['texture'].endswith('Arrow.tga'):
            arrow=Image.open(root/'Wayfinder/Media/Arrow.tga').convert('RGBA').resize((w,h));image.alpha_composite(arrow,(x,y))
    draw.text((28,730),'Development render from actual frame calls · synthetic quest data',font=ImageFont.truetype(font_path,11),fill='#8398a5')
    draw.text((28,749),'Fonts and textures may appear slightly different in the game client.',font=ImageFont.truetype(font_path,11),fill='#8398a5')
    out=root/f'docs/previews/{subject}.png';out.parent.mkdir(parents=True,exist_ok=True);image.convert('RGB').save(out)
    print(out)

