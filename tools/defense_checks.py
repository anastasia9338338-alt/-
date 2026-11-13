"""Behavior checks for the v4.77 controllers, extracted from the final bundle."""
from pathlib import Path
import subprocess


def run_defense_checks(modules, runner, folder):
    support=Path(__file__).resolve().parent/'feature_tests'
    program=(support/'defense477_prefix.luau').read_text()
    for name in ('WalkingRig','BlobmanCadence','AntiExplore','BlobmanDefense','BlobmanKick','BlobmanAura'):
        program+='\nmodules.'+name+'=(function(...)\n'+modules[name]+'\nend)(requireModule)\n'
    body=(support/'defense477_body.luau').read_text()
    body=body.split("test('default theme retains",1)[0]
    program+=body+"\nprint('ALL DEFENSE CHECKS PASSED: '..checks)\n"
    path=Path(folder)/'defense477.luau';path.write_text(program)
    result=subprocess.run([str(runner),str(path)],text=True,capture_output=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    print(result.stdout.strip())
