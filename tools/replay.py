"""Replay local /wf trace JSON through the pure selector. No game APIs or network."""
from pathlib import Path
import json
import math
import subprocess
import sys
import tempfile
root=Path(__file__).resolve().parents[1]

def lua_string(value):
    out=['"']
    for c in value:
        if c in {'"','\\'}: out.append('\\'+c)
        elif ord(c)<32 or ord(c)==127: out.append('\\'+format(ord(c),'03d'))
        else: out.append(c)
    return ''.join(out)+'"'

def literal(value,field=''):
    if value is None: return 'nil'
    if isinstance(value,bool): return 'true' if value else 'false'
    if isinstance(value,(float,int)):
        if not math.isfinite(value): raise ValueError('Non-finite replay number')
        return repr(value)
    if isinstance(value,str): return lua_string(value)
    if isinstance(value,list): return '{'+','.join(literal(v,field) for v in value)+'}'
    if isinstance(value,dict):
        entries=[]
        for k,v in value.items():
            key=int(k) if field in {'completed','activeByID','gates'} and str(k).isdigit() else str(k)
            entries.append('['+literal(key)+']='+literal(v,str(k)))
        return '{'+','.join(entries)+'}'
    raise ValueError('Unsupported replay value')

path=Path(sys.argv[1])
if path.stat().st_size>10_000_000: raise SystemExit('Replay exceeds 10 MB')
data=json.loads(path.read_text(encoding='utf-8'),parse_constant=lambda v: (_ for _ in ()).throw(ValueError(v)))
if data.get('schema')!=1 or not isinstance(data.get('frames'),list) or not data['frames']:
    raise SystemExit('Expected replay schema 1 with at least one frame')
program='''unpack=unpack or table.unpack
for _,name in ipairs({"Common","Data","Planner"}) do dofile("Wayfinder/"..name..".lua") end
local frames=REPLAY_FRAMES
for i,frame in ipairs(frames) do
 local route,queue,detail=Wayfinder.SelectRoute(frame.input)
 assert(route.key==frame.expected.key,"Replay decision mismatch in frame "..i)
 assert(#queue==#frame.expected.queue,"Replay queue length mismatch in frame "..i)
 for j,step in ipairs(queue) do assert(step.key==frame.expected.queue[j],"Replay queue mismatch in frame "..i) end
 assert((detail.clearPin==true)==(frame.expected.clearPin==true),"Replay focus mismatch in frame "..i)
end
print(#frames.." replay frames matched")
'''.replace('REPLAY_FRAMES',literal(data['frames']))
with tempfile.TemporaryDirectory(prefix='wayfinder-replay-') as directory:
    script=Path(directory)/'replay.lua';script.write_text(program,encoding='utf-8')
    raise SystemExit(subprocess.call([sys.executable,str(root/'tools/run_lua.py'),str(script)],cwd=root))
