"""Guard the documented required and optional addon dependencies."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
workflow = (root / '.github' / 'workflows' / 'verify.yml').read_text()
toc = (root / 'Trailwarden' / 'Trailwarden.toc').read_text()
required = re.search(r'^## Dependencies: (.+)$', toc, re.M)
optional = re.search(r'^## OptionalDeps: (.+)$', toc, re.M)
if not required or [v.strip() for v in required.group(1).split(',')] != ['QuestieDB']:
    raise SystemExit('QuestieDB must remain the only required addon dependency.')
if not optional or {v.strip() for v in optional.group(1).split(',')} != {'Questie', 'OpenMap'}:
    raise SystemExit('Questie and OpenMap must remain optional addon dependencies.')
provider_archive = '/tmp/trailwarden-provider/QuestieDB-1.0.14-Forever.zip'
provider_digest = 'becb9b3cea4a99ae31f115a187179c242f5cf8ef28bf4f9579a86393f18f45c3'
download = workflow.find('https://github.com/Questie/QuestieDB/releases/download/v1.0.14/QuestieDB-1.0.14-Forever.zip')
verify = workflow.find('sha256sum --check --strict')
extract = workflow.find(f'unzip -q {provider_archive}')
if download < 0 or verify < download or extract < verify or provider_digest not in workflow or provider_archive not in workflow:
    raise SystemExit('The pinned QuestieDB Forever 1.0.14 archive must pass its SHA-256 check before extraction.')
if 'tools/generate_catalog_index.py' not in workflow or '--check' not in workflow:
    raise SystemExit('The generated provider zone index must be checked against the verified provider.')
print('Installation matrix metadata: QuestieDB required; Questie and OpenMap optional.')
