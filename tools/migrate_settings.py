"""Copy Wayfinder settings into Trailwarden without executing Lua or overwriting files.

Exit WoW first, then run this with the path to your WoW WTF directory.
"""
from pathlib import Path
import argparse
import re


def migrate(source):
    source = Path(source)
    target = source.with_name('Trailwarden.lua')
    text = source.read_text(encoding='utf-8-sig')
    # Only rename the root assignment; preserve strings and all character data.
    text, count = re.subn(r'\AWayfinderDB(?=\s*=)', 'TrailwardenDB', text.lstrip(), count=1)
    if count != 1 or not re.search(r'\["profiles"\]\s*=\s*\{', text):
        raise ValueError(f'Not recognized as this project\'s Wayfinder settings: {source}')
    with target.open('x', encoding='utf-8', newline='') as output:
        output.write(text)
    return target


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('wtf', type=Path)
    args = parser.parse_args()
    sources = sorted(args.wtf.glob('Account/*/SavedVariables/Wayfinder.lua'))
    if not sources:
        parser.error('No Account/*/SavedVariables/Wayfinder.lua files found.')
    for source in sources:
        try:
            print(f'Created {migrate(source)}; original preserved.')
        except (FileExistsError, ValueError) as error:
            parser.exit(1, f'{error}\nNo existing Trailwarden settings were overwritten.\n')
