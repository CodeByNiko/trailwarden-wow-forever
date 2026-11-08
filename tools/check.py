"""Run the release checks, failing immediately on any failed suite."""
from pathlib import Path
import subprocess
import sys
root=Path(__file__).resolve().parents[1]
commands=[
 ['tools/run_lua.py','tests/scenarios.lua'],
 ['tools/run_lua.py','tests/engine.lua'],
 ['tools/run_lua.py','tests/provider_contract.lua'],
 ['tools/run_lua.py','tests/experience.lua'],
 ['tools/replay.py','tests/journey-replay.json'],
 ['tools/replay.py','tests/replay-export.json'],
 ['tools/replay.py','tests/experience-replay.json'],
]
for command in commands:
    subprocess.run([sys.executable,*command],cwd=root,check=True)
print('All scenario, engine, provider-contract and replay suites passed')

