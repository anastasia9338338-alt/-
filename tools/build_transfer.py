"""Build the user's standalone Astral import without downloading runtime code."""
from pathlib import Path
import argparse,re,zipfile

ROOT=Path(__file__).resolve().parents[1]
PATTERN=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
args=argparse.ArgumentParser()
args.add_argument('--module-dir',type=Path,help='Reviewed modules extracted from the user-uploaded base')
a=args.parse_args()
source=(ROOT/'astral.lua').read_text()
updates={}
if a.module_dir:
    updates.update({p.stem:p.read_text()for p in a.module_dir.glob('*.luau')})
for name in ('Library','UIMotion','Watermark','UIStyle','GUIStyle'):
    updates[name]=(ROOT/'ui'/f'{name}.luau').read_text()
updates['PalletRagdoll']=(ROOT/'kick/ReferencePallet.luau').read_text()
updates['ReferenceAntiKick']=(ROOT/'kick/ReferenceAntiKick.luau').read_text()
updates['KickLoop']=(ROOT/'kick/KickLoop.luau').read_text()
seen=set()
def replace(match):
    name,body=match.groups();seen.add(name)
    body=updates.get(name,body).rstrip('\n')
    return f'sources.{name} = [========[\n{body}\n]========]'
source=PATTERN.sub(replace,source)
for name in updates.keys()-seen:
    source=source.replace('local sources = {}','local sources = {}\n'+f'sources.{name} = [========[\n{updates[name].rstrip()}\n]========]',1)
(ROOT/'astral.lua').write_text(source)
with zipfile.ZipFile(ROOT/'astral.zip','w',zipfile.ZIP_DEFLATED,compresslevel=6)as z:z.write(ROOT/'astral.lua','astral.lua')
print('Built standalone Astral Lua and identical ZIP; no remote publication')
