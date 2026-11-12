"""Run the release checks, failing immediately on any failed suite."""
from pathlib import Path
import subprocess
import sys
root=Path(__file__).resolve().parents[1]
commands=[
 ['tools/check_install_matrix.py'],
 ['tools/check_release_consistency.py'],
 ['tools/run_lua.py','tests/scenarios.lua'],
 ['tools/run_lua.py','tests/engine.lua'],
 ['tools/run_lua.py','tests/provider_contract.lua'],
 ['tools/run_lua.py','tests/experience.lua'],
 ['tools/run_lua.py','tests/safety.lua'],
 ['tools/run_lua.py','tests/travel.lua'],
 ['tools/run_lua.py','tests/localization.lua'],
 ['tools/run_lua.py','tests/feedback.lua'],
 ['tools/run_lua.py','tests/performance.lua'],
 ['tools/replay.py','tests/journey-replay.json'],
 ['tools/replay.py','tests/replay-export.json'],
 ['tools/replay.py','tests/experience-replay.json'],
 ['tools/replay.py','tests/safety-replay.json'],
]
for command in commands:
    subprocess.run([sys.executable,*command],cwd=root,check=True,timeout=90)
print('All scenario, engine, provider-contract and replay suites passed')

