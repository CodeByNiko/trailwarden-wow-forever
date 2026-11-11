"""Guard the documented required and optional addon dependencies."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
toc = (root / 'Trailwarden' / 'Trailwarden.toc').read_text()
required = re.search(r'^## Dependencies: (.+)$', toc, re.M)
optional = re.search(r'^## OptionalDeps: (.+)$', toc, re.M)
if not required or [v.strip() for v in required.group(1).split(',')] != ['QuestieDB']:
    raise SystemExit('QuestieDB must remain the only required addon dependency.')
if not optional or {v.strip() for v in optional.group(1).split(',')} != {'Questie', 'OpenMap'}:
    raise SystemExit('Questie and OpenMap must remain optional addon dependencies.')
print('Installation matrix metadata: QuestieDB required; Questie and OpenMap optional.')
