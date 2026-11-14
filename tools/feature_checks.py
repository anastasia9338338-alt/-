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
    if '-- ASTRAL_REPLACE_RUNNING_BEGIN'in modules.get('Bootstrap',''):
        boot=modules['Bootstrap'];guard=boot.split('-- ASTRAL_REPLACE_RUNNING_BEGIN',1)[1].split('-- ASTRAL_REPLACE_RUNNING_END',1)[0]
        run('startup_replace',read('startup_replace_body.luau').replace('__GUARD__',guard))
    if '-- Faster escape owns one held session;' in modules.get('Main',''):
        main=modules['Main']
        escape=main[main.index('\t\t-- Faster escape owns one held session;'):main.index('\t\t-- End bounded faster escape.')]
        start=main.index('\t\tdo\n\t\tlocal stickyThread, stickyGeneration')
        sticky=main[start:main.index('\t\t-- End bounded sticky defense.',start)]
        run('defense_workers',read('defense_workers_prefix.luau')+'\n'+escape+'\n'+sticky+'\n'+read('defense_workers_body.luau'))
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
    if 'GameShopStyle'in modules:
        run('game_shop483',read('ui_engine_mock.luau')+'\n'+read('ui_native_mock.luau')+'\nlocal Shop=(function()\n'+modules['GameShopStyle']+'\nend)()\n'+read('game_shop483_body.luau'))
    if 'FrameArtwork'in modules:
        run('frame_artwork',read('ui_engine_mock.luau')+'\n'+read('ui_native_mock.luau')+'\nlocal Art=(function()\n'+modules['FrameArtwork']+'\nend)()\n'+read('gui_extensions_body.luau'))
    if 'FrameImageFiles'in modules:
        from frame_codec_checks import run_codec_checks
        run_codec_checks(modules,runner,folder)
    if 'GUIAppearance'in modules:
        main=modules['Main']
        assert main.index('GUI = v19:AddTab')>main.index('Settings = v19:AddTab')
        assert main.count('GUI = v19:AddTab')==1
        assert 'tbl12.GUIAppearance:Sync()'in main[main.index('lib:FinishStartup()'):]
        assert 'tbl12.GUIAppearance:Dispose()'in main
    if 'PCLDAvatarESP'in modules:
        main=modules['Main']
        tweaks=main[main.index('local v20 = tbl15.Visual:AddLeftTabbox("Game Tweaks")'):main.index('local Sky = tbl15.Visual:AddLeftGroupbox',main.index('local v20 = tbl15.Visual:AddLeftTabbox("Game Tweaks")'))]
        assert tweaks.count('v20:AddTab(')==2 and 'volume-2'not in tweaks and '"crosshair"'not in tweaks
        assert 'boolValue.Name = "RootAttachment"'not in main
        assert 'BlobmanRemoveArms'not in main and 'Remove Blobman Arms'not in main
        assert 'tbl12.PCLDAvatars:Has(arg)'in main and main.count('tbl12.PCLDAvatars:Render()')>=2
        assert 'tbl15.Player:AddLeftGroupbox("Camera", "camera")'in main
        assert 'Enabled=function()return not flag11 and not tbl8.GucciAntiGrab and tbl8.AntiGrab end'in main
        for token in ('JumpRequest=UserInputService.JumpRequest','tbl12.BlobmanRide:Dismount()','tbl12.PCLDAvatars:SetMode(value)','CatalogRoots=function()','Vector3.new(0,-20,0)'):
            assert token in main,('missing native integration',token)
    if 'PCLDAvatarESP'in modules:
        run('pcld_avatar',read('model_mock.luau')+'\nlocal Avatars=(function()\n'+modules['PCLDAvatarESP']+'\nend)()\n'+read('pcld_avatar_body.luau'))
    if 'Discover'in modules.get('AssetCatalog',''):
        program=read('model_mock.luau')+'\nlocal Catalog=(function()\n'+modules['AssetCatalog']+'\nend)()\n'
        program+='local ObjectESP=(function(...)\n'+modules['ObjectESP']+'\nend)(function()return Catalog end)\n'+read('catalog479_body.luau')
        run('catalog479',program)
    if 'local spinState = {Enabled = false}'in modules.get('Main',''):
        main=modules['Main'];start=main.index('local spinState = {Enabled = false}')
        end=main.index('            Character:AddToggle("AstralWallClimb"',start)
        program=read('spin_prefix.luau')+'\n'+main[start:end]+'\n'+read('spin_body.luau')
        run('spin',program)
    if 'AstralTeleportCursorKey'in modules.get('Main',''):
        main=modules['Main'];start=main.index('launcher:AddLabel("Teleport To Cursor")')
        start=main.index('Callback=function()',start)+len('Callback=')
        end=main.index('\n            end})',start)+len('\n            end')
        program=read('model_mock.luau')+'\n'+read('teleport_cursor_prefix.luau')+'\nlocal teleport='+main[start:end]+'\n'+read('teleport_cursor_body.luau')
        run('teleport_cursor',program)
    if {'BlobmanKick','BlobmanDefense','AntiExplore'}<=modules.keys():
        from defense_checks import run_defense_checks
        run_defense_checks(modules,runner,folder)
    elif 'BlobmanCadence'in modules:
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
        from ui_checks import program
        run('nativeui',program(modules))
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
    if 'UIMotion'in modules:
        motion_body='ui_motion_group_body.luau'if 'GroupTransparency'in modules['UIMotion']else 'ui_motion_body.luau'
        run('ui_motion',read('ui_engine_mock.luau')+'\nlocal Motion=(function()\n'+modules['UIMotion']+'\nend)()\n'+read(motion_body))
    if 'Watermark'in modules:
        run('watermark',read('ui_engine_mock.luau')+'\nlocal HUD=(function()\n'+modules['Watermark']+'\nend)()\n'+read('watermark_body.luau'))
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
