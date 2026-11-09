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
    if 'BlobmanAura'in modules and 'WaterWalk'in modules:
        program=read('model_mock.luau')+'\nlocal PhysicalProperties={new=function(...)return{}end}\n'
        program+='local WaterSurface=(function()\n'+modules['WaterSurface']+'\nend)()\n'
        program+='local Aura=(function()\n'+modules['BlobmanAura']+'\nend)()\nlocal Walk=(function()\n'+modules['WaterWalk']+'\nend)()\n'+read('survival_body.luau')
        run('survival',program)
    if 'ESPMotion'in modules:
        run('motion',read('motion_mock.luau')+'\nlocal Motion=(function()\n'+modules['ESPMotion']+'\nend)()\n'+read('motion_body.luau'))
    if 'ObjectESP'in modules:
        run('esp',read('esp_mock.luau')+'\nlocal ObjectESP=(function(...)\n'+modules['ObjectESP']+"\nend)(function(name)assert(name=='AssetCatalog');return {Items={Train='train-picture',BallSnowball='snow-picture'}}end)\n"+read('esp_body.luau'))
    if 'AntiGrabWalk'in modules:
        program=read('antigrab_mock.luau')+'\nlocal WalkingRig=(function()\n'+modules['WalkingRig']+'\nend)()\n'
        program+='local Impulse=(function()\n'+modules['GrabImpulse']+'\nend)()\n'
        program+='Guard=(function(...)\n'+modules['AntiGrabWalk']+'\nend)(function(name)if name=="WalkingRig"then return WalkingRig elseif name=="GrabImpulse"then return Impulse end;error(name)end)\n'+read('antigrab_body.luau')
        run('antigrab',program)
    for module,alias,body in [('GrabImpulse','Impulse','grab_impulse_body.luau'),('BlobmanRide','Ride','blobman_ride_body.luau'),
            ('FoodRemover','Remover','food_remover_body.luau'),('BlackholeVolume','Volume','blackhole_volume_body.luau'),('UFOBlaster','Blaster','ufo_blaster_body.luau'),
            ('SlideTeleport','Slide','slide_teleport_body.luau'),('PalletMagnet','Magnet','pallet_magnet_body.luau'),
            ('WaterRescue','Rescue','water_rescue_body.luau'),('BlobmanCadence','Cadence','blobman_cadence_body.luau')]:
        if module in modules:
            run(module.lower(),read('model_mock.luau')+'\nlocal PhysicalProperties={new=function(...)return{...}end}\nlocal '+alias+'=(function()\n'+modules[module]+'\nend)()\n'+read(body))
    if 'AstralTeleportCursorKey'in modules.get('Main',''):
        main=modules['Main'];start=main.index('launcher:AddLabel("Teleport To Cursor")')
        start=main.index('Callback=function()',start)+len('Callback=')
        end=main.index('\n            end})',start)+len('\n            end')
        program=read('model_mock.luau')+'\n'+read('teleport_cursor_prefix.luau')+'\nlocal teleport='+main[start:end]+'\n'+read('teleport_cursor_body.luau')
        run('teleport_cursor',program)
    if 'BlobmanCadence'in modules:
        main=modules['Main'];start=main.index('        tbl14.BlobLoopTokens=')
        end=main.index('\n\t\ttbl14.LoopLock =',start)
        program=read('model_mock.luau')+'\nlocal Cadence=(function()\n'+modules['BlobmanCadence']+'\nend)()\n'+read('blobman_loop_prefix.luau')+'\n'+main[start:end]+'\n'+read('blobman_loop_body.luau')
        run('blobman_loop',program)
    if 'local function spawnBlasterToy'in modules.get('Main',''):
        main=modules['Main'];start=main.index('        local function spawnBlasterToy')
        end=main.index('        tbl12.UFOBlaster=',start)
        program=read('model_mock.luau')+'\nlocal Flags=(function()\n'+modules['GameFlags']+'\nend)()\n'+read('ufo_spawn_prefix.luau')+'\n'+main[start:end]+'\n'+read('ufo_spawn_body.luau')
        run('ufo_spawn',program)
    if 'PalletRagdoll'in modules and 'Resonance29Ragdoll'in modules:
        program=read('kick_mock.luau')+'\nlocal Source=(function()\n'+modules['Resonance29Ragdoll']+'\nend)()\n'
        program+='local Ownership=(function()\n'+modules['PalletOwnership']+'\nend)()\nlocal Reaction=(function()\n'+modules['PalletReaction']+'\nend)()\n'
        if 'PalletStroke'in modules:
            program+='local Stroke=(function()\n'+modules['PalletStroke']+'\nend)()\nlocal Cadence=(function()\n'+modules['PalletCadence']+'\nend)()\n'
        program+='local Pallet=(function(...)\n'+modules['PalletRagdoll']+'\nend)(function(name)if name=="Resonance29Ragdoll"then return Source elseif name=="PalletOwnership"then return Ownership elseif name=="PalletReaction"then return Reaction elseif name=="PalletStroke"then return Stroke elseif name=="PalletCadence"then return Cadence end;error(name)end)\n'
        program+=read('kick_body.luau'if 'PalletStroke'in modules else 'native_pallet_body.luau')
        run('kick',program)
        run('pallet_reaction',read('model_mock.luau')+'\nlocal Reaction=(function()\n'+modules['PalletReaction']+'\nend)()\n'+read('pallet_reaction_body.luau'))
        if 'PalletCadence'in modules:
            run('pallet_cadence','local Cadence=(function()\n'+modules['PalletCadence']+'\nend)()\n'+read('pallet_cadence_body.luau'))
        run('pallet_ownership',read('kick_mock.luau')+'\nlocal Ownership=(function()\n'+modules['PalletOwnership']+'\nend)()\n'+read('pallet_ownership_body.luau'))
        loop_source='\nlocal Handoff=(function()\n'+modules['KickHandoff']+'\nend)()\nlocal Loop=(function(...)\n'+modules['KickLoop']+'\nend)(function(name)assert(name=="KickHandoff");return Handoff end)\n'
        run('kick_channel',read('kick_mock.luau')+loop_source+read('kick_channel_body.luau'))
        run('kick_handoff',read('kick_mock.luau')+loop_source+read('kick_handoff_body.luau'))
        run('kick_eki',read('kick_mock.luau')+loop_source+read('kick_eki_body.luau'))
        start=modules['Main'].index('tbl12.SNO = function');end=modules['Main'].index('tbl12.RNO = function',start)
        sno=modules['Main'][start:end]
        run('pallet_sno',read('kick_mock.luau')+'\n'+read('pallet_sno_prefix.luau')+'\n'+sno+'\n'+read('pallet_sno_body.luau'))
    if 'TheWorstUIV2'in modules:
        from ui_checks import program
        run('theworstui',program(modules))
    elif 'Library'in modules:
        library=modules['Library']
        slider=library[library.index('    function Funcs:AddSlider('):library.index('    function Funcs:AddDropdown(')]
        run('slider',read('slider_mock.luau')+'\n'+slider+'\n'+read('slider_body.luau'))
        start=library.index('        table.insert(KeyPicker.Connections, UserInputService.InputBegan:Connect(')
        end=library.index('\n        KeyPicker:Update()',start)
        declaration=re.search(r'local SlideForwardConn, SlideBackConn, InputChanged',library)
        assert declaration,'Hold-key observer escaped its picker scope'
        cleanup=re.search(r'Library:OnUnload\(function\(\)\s+if InputChanged then InputChanged:Disconnect\(\);InputChanged=nil end\s+end\)',library)
        assert cleanup,'Hold-key observer lacks direct unload cleanup'
        run('keybind',read('keybind_mock.luau')+declaration[0]+'\n'+cleanup[0]+'\n'+library[start:end]+read('keybind_body.luau'))
    if {'AquaAssets','AquaPose','AquaMesh','AquaModel'}<=modules.keys():
        program=read('model_mock.luau')+'\n'+read('aqua_mock.luau')
        for name,alias in [('AquaAssets','Assets'),('AquaPose','Pose'),('AquaMesh','Mesh'),('AquaEffects','Effects')]:
            program+='\nlocal '+alias+'=(function()\n'+modules[name]+'\nend)()\n'
        program+='local Editable=(function(...)\n'+modules['AquaEditable']+'\nend)(function(name)assert(name=="AquaMesh");return Mesh end)\n'
        program+='local function BuildModel(meshModule) return (function(...)\n'+modules['AquaModel']+'\nend)(function(name)if name=="AquaAssets"then return Assets elseif name=="AquaPose"then return Pose elseif name=="AquaMesh"then return meshModule elseif name=="AquaEffects"then return Effects elseif name=="AquaEditable"then return Editable end;error(name)end)end\nlocal Model=BuildModel(Mesh)\n'
        run('aqua',program+read('aqua_body.luau'))
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
