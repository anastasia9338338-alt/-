"""Verify the embedded JPEGs, exact user URLs and independently recorded hashes."""
from pathlib import Path
import base64, hashlib, json, re

ROOT=Path(__file__).resolve().parents[1]
def check(modules):
    manifest=json.loads((ROOT/'ui/background-sources.json').read_text())
    images=dict(re.findall(r'(Winter\d+)="([A-Za-z0-9+/=]+)"',modules['BackgroundAssets']))
    sources=re.findall(r'Source="([^"]+)"',modules['BackgroundCatalog'])
    assert len(manifest)==len(images)==len(sources)==10
    assert manifest[0]['source']=='https://i.pinimg.com/736x/1f/e5/29/1fe529587285dae0fd004497ac8d2cc1.jpg'
    assert manifest[1]['source']=='https://i.pinimg.com/736x/90/6f/58/906f58d7915dc3d12b1c27fed66a0177.jpg'
    for item in manifest:
        data=base64.b64decode(images[item['key']],validate=True)
        assert len(data)==item['bytes'] and hashlib.sha256(data).hexdigest()==item['sha256'],item['key']
        assert data.startswith(b'\xff\xd8') and data.endswith(b'\xff\xd9'),item['key']
        assert item['source'] in sources
    print('PASS: 10 bundled winter JPEGs, two exact user photos, source URLs and SHA-256 readback')
