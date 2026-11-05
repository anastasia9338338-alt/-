"""Run feature behavior checks against modules from the exact delivered bundle.

These are fake-engine regression scenarios, not live Roblox validation.
"""
from pathlib import Path
import argparse,re,subprocess,tempfile


def run_feature_checks(modules,runner,folder):
    support=Path(__file__).resolve().parent/'feature_tests'
    def read(name):return (support/name).read_text()
    def run(name,program):
        path=Path(folder)/(name+'.luau');path.write_text(program)
        result=subprocess.run([str(runner),str(path)],capture_output=True,text=True)
        assert result.returncode==0,(name,result.stdout,result.stderr)
        print(result.stdout.strip())
    if 'ESPMotion'in modules:
        run('motion',read('motion_mock.luau')+'\nlocal Motion=(function()\n'+modules['ESPMotion']+'\nend)()\n'+read('motion_body.luau'))
    if 'ObjectESP'in modules:
        run('esp',read('esp_mock.luau')+'\nlocal ObjectESP=(function(...)\n'+modules['ObjectESP']+"\nend)(function(name)assert(name=='AssetCatalog');return {Items={Train='train-picture',BallSnowball='snow-picture'}}end)\n"+read('esp_body.luau'))
    if 'AntiGrabWalk'in modules:
        run('antigrab',read('antigrab_mock.luau')+'\nlocal Guard=(function()\n'+modules['AntiGrabWalk']+'\nend)()\n'+read('antigrab_body.luau'))
    if 'PalletRagdoll'in modules and 'Resonance29Ragdoll'in modules:
        program=read('kick_mock.luau')+'\nlocal Source=(function()\n'+modules['Resonance29Ragdoll']+'\nend)()\n'
        program+='local Pallet=(function(...)\n'+modules['PalletRagdoll']+'\nend)(function(name)assert(name=="Resonance29Ragdoll");return Source end)\n'+read('kick_body.luau')
        run('kick',program)
    if 'Library'in modules:
        library=modules['Library']
        slider=library[library.index('    function Funcs:AddSlider('):library.index('    function Funcs:AddDropdown(')]
        run('slider',read('slider_mock.luau')+'\n'+slider+'\n'+read('slider_body.luau'))
        start=library.index('        table.insert(KeyPicker.Connections, UserInputService.InputBegan:Connect(')
        end=library.index('\n        KeyPicker:Update()',start)
        declaration=re.search(r'local SlideForwardConn, SlideBackConn, InputChanged',library)
        assert declaration,'Hold-key observer escaped its picker scope'
        run('keybind',read('keybind_mock.luau')+declaration[0]+'\n'+library[start:end]+read('keybind_body.luau'))
    if 'SahurModel'in modules and 'LocalModels'in modules:
        program=read('model_mock.luau')+'\nlocal Sahur=(function()\n'+modules['SahurModel']+'\nend)()\n'
        program+='local Models=(function(...)\n'+modules['LocalModels']+'\nend)(function(name)assert(name=="SahurModel");return Sahur end)\n'+read('model_body.luau')
        run('model',program)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--bundle',type=Path,default=Path(__file__).resolve().parents[1]/'astral.lua')
    parser.add_argument('--luau',required=True,type=Path)
    args=parser.parse_args()
    pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
    modules=dict(pattern.findall(args.bundle.read_text()))
    assert modules,'No bundled modules found'
    with tempfile.TemporaryDirectory(prefix='astral-features-')as temp:run_feature_checks(modules,args.luau,Path(temp))


if __name__=='__main__':main()
