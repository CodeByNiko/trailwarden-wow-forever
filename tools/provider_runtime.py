"""Load a checksum-verified provider directory in an isolated Lua 5.1 emulator."""
import base64
from pathlib import Path
import zlib
import cbor2
from lupa.lua51 import LuaRuntime

def load_provider(provider, expected_version=None, build="70245"):
    provider=Path(provider).resolve()
    lua=LuaRuntime(encoding=None,unpack_returned_tuples=True)
    namespace=lua.table(); metadata={}; files=[]
    for line in (provider/'QuestieDB_Forever.toc').read_bytes().splitlines():
        if line.startswith(b'## '):
            key,_,value=line[3:].partition(b':');metadata[key]=value.strip()
        elif line.strip() and not line.startswith(b'#'):
            files.append(line.decode().replace('\\','/'))
    version=metadata.get(b'Version',b'').decode()
    if expected_version and version!=expected_version:
        raise ValueError(f'Expected provider {expected_version}, found {version}')
    def to_lua(value):
        if isinstance(value,dict): return lua.table_from({to_lua(k):to_lua(v) for k,v in value.items()})
        if isinstance(value,(list,tuple)): return lua.table_from([to_lua(v) for v in value])
        return value.encode() if isinstance(value,str) else value
    def decompress(value,_kind):
        for window in (15,-15,31):
            try: return zlib.decompress(value,window)
            except zlib.error: pass
        raise ValueError('Unsupported provider compression')
    g=lua.globals()
    g.py_build=build.encode()
    g.py_metadata=lambda _addon,key: metadata.get(key)
    g.py_cbor=lambda value:to_lua(cbor2.loads(value))
    g.py_base64=base64.b64decode;g.py_decompress=decompress
    lua.execute(b'''GetAddOnMetadata=function(a,k) return py_metadata(a,k) end
C_AddOns={GetAddOnMetadata=GetAddOnMetadata}
C_EncodingUtil={DecodeBase64=function(s) return py_base64(s) end,DecompressString=function(s,k) return py_decompress(s,k) end,DeserializeCBOR=function(s) return py_cbor(s) end}
GetLocale=function() return "enUS" end
GetBuildInfo=function() return "1.60.1",py_build,"",16001 end
UnitFactionGroup=function() return "Alliance" end
UnitClassBase=function() return "WARRIOR",1 end
UnitRace=function() return "Night Elf","NightElf",4 end''')
    for name in files:
        path=(provider/name).resolve()
        if not path.is_relative_to(provider): raise ValueError('Provider path escapes directory')
        lua.execute(path.read_bytes(),b'QuestieDB',namespace)
    if namespace[b'RequireContract'](3) is not True: raise ValueError('Provider contract 3 required')
    return lua,namespace,version
