"""Run the deterministic addon scenarios with a Lua executable or system liblua.
The liblua fallback is for development only; it is never shipped as addon code.
"""
import ctypes
import ctypes.util
from pathlib import Path
import shutil
import subprocess
import sys
root = Path(__file__).resolve().parents[1]
script = sys.argv[1] if len(sys.argv) > 1 else 'tests/scenarios.lua'
for executable in ('lua5.1', 'luajit', 'lua'):
    if shutil.which(executable):
        raise SystemExit(subprocess.call([executable, script], cwd=root))
lib = ctypes.CDLL(ctypes.util.find_library('lua5.4') or 'liblua5.4.so.0')
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]
state = lib.luaL_newstate()
lib.luaL_openlibs(state)
import os
os.chdir(root)
result = lib.luaL_loadfilex(state, str(script).encode(), None)
if result == 0:
    result = lib.lua_pcallk(state, 0, -1, 0, 0, None)
if result:
    print(lib.lua_tolstring(state, -1, None).decode(), file=sys.stderr)
lib.lua_close(state)
raise SystemExit(1 if result else 0)
