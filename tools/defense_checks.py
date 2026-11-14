"""Native Blobman and movement-isolation scenarios from the final bundle."""
from pathlib import Path
import subprocess

def run_defense_checks(modules, runner, folder):
    support=Path(__file__).resolve().parent/'feature_tests'
    for scenario in ('blobman_defense479','anti_explore480','blobman_kick479'):
        program=(support/'defense477_prefix.luau').read_text()
        for name in ('WalkingRig','BlobmanCadence','AntiExplore','BlobmanDefense','BlobmanKick','BlobmanAura'):
            program+='\nmodules.'+name+'=(function(...)\n'+modules[name]+'\nend)(requireModule)\n'
        program+=(support/(scenario+'_body.luau')).read_text()
        path=Path(folder)/(scenario+'.luau');path.write_text(program)
        result=subprocess.run([str(runner),str(path)],text=True,capture_output=True)
        assert result.returncode==0,(scenario,result.stdout,result.stderr)
        print(result.stdout.strip())
