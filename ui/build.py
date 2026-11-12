"""Embed the reviewed UI sources into the existing standalone Astral bundle."""
from pathlib import Path
import re,zipfile

root=Path(__file__).resolve().parents[1]
pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
bundle=(root/'astral.lua').read_text()
replacements={name:(root/'ui'/f'{name}.luau').read_text().rstrip()+'\n'
              for name in ('Library','Watermark','UIMotion')}
retired={'TheWorstUIV2','Presentation'}
known={m[0]for m in pattern.findall(bundle)}
def replace(m):
    if m[1] in retired: return ''
    return f'sources.{m[1]} = [========[\n{replacements[m[1]]}\n]========]'if m[1]in replacements else m[0]
bundle=pattern.sub(replace,bundle)
for name,body in replacements.items():
    if name not in known:
        bundle=bundle.replace('local sources = {}','local sources = {}\n'+f'sources.{name} = [========[\n{body}\n]========]',1)
(root/'astral.lua').write_text(bundle)
with zipfile.ZipFile(root/'astral.zip','w',compression=zipfile.ZIP_DEFLATED,compresslevel=6)as z:z.write(root/'astral.lua','astral.lua')
print('Embedded native Astral sidebar UI and draggable watermark; ZIP rebuilt')
