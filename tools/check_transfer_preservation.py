"""Compare the deliverable with the user's imported v5 base, not old git HEAD."""
from pathlib import Path
import hashlib,json,re

ROOT=Path(__file__).resolve().parents[1]
def check(modules):
    baseline=json.loads((ROOT/'transfers/user-v5-base.json').read_text())
    allowed={'Library','Main','PalletRagdoll','UIStyle','GUIStyle','KickLoop','TargetPanel','Bootstrap','Notices'}
    assert set(baseline['modules'])<=modules.keys(),'An uploaded module was removed'
    changed=[]
    for name,digest in baseline['modules'].items():
        if hashlib.sha256(modules[name].rstrip('\n').encode()).hexdigest()!=digest:
            assert name in allowed,('Unexpected change to the uploaded base',name)
            changed.append(name)
    ids=set(x for body in modules.values()for x in re.findall(r':Add(?:Toggle|Checkbox|Slider|Dropdown|Input|KeyPicker|ColorPicker)\(\s*["\']([^"\']+)',body))
    missing=set(baseline['control_ids'])-ids
    assert not missing,('Existing control IDs removed',sorted(missing))
    assert 'ReferenceAntiKick'in modules
    assert 'ReferenceTrajectory'in modules['PalletRagdoll']
    assert 'NativeTouch'not in modules['PalletRagdoll'],'Replacement still depends on synthetic contacts'
    print(f"PASS: {len(baseline['modules'])} uploaded modules and {len(baseline['control_ids'])} existing control IDs retained; reviewed changes: {', '.join(changed)}")

if __name__=='__main__':
    modules=dict(re.findall(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',(ROOT/'astral.lua').read_text(),re.M|re.S))
    check(modules)
