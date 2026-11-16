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
    if 'AntiGrabWalk'in modules:
        main=modules['Main'];a=main.index('GrabWelds=function()',main.index('tbl12.AntiGrabWalk=requireModule'))
        b=main.index('\n                        RecoverAnimation=',a)
        callback=main[a+len('GrabWelds='):b].strip().rstrip(',')
        run('grab_discovery490',read('model_mock.luau')+'\n'+read('grab_discovery490_body.luau').replace('__ACTUAL_DISCOVERY__',callback))
    for module,alias,body in [('GrabImpulse','Impulse','grab_impulse_body.luau'),('BlobmanRide','Ride','blobman_ride_body.luau'),
            ('FoodRemover','Remover','food_remover_body.luau'),('FreezePCLD','Freeze','freeze_pcld_body.luau'),('DestroyDesync','Destroy','destroy_desync490_body.luau'),('AntiKickItems','Items','antikick490_body.luau'),('BlackholeVolume','Volume','blackhole_volume_body.luau'),('UFOBlaster','Blaster','ufo_blaster_body.luau'),
            ('SlideTeleport','Slide','slide_teleport_body.luau'),('PalletMagnet','Magnet','pallet_magnet_body.luau'),
            ('WaterRescue','Rescue','water_rescue_body.luau'),('BlobmanCadence','Cadence','blobman_cadence_body.luau')]:
        if module in modules:
            run(module.lower(),read('model_mock.luau')+'\nlocal PhysicalProperties={new=function(...)return{...}end}\nlocal '+alias+'=(function()\n'+modules[module]+'\nend)()\n'+read(body))
    if {'BlobmanRiderGrab','ExplosionLegs'}<=modules.keys():
        program=read('model_mock.luau')+'\nlocal Rider=(function()\n'+modules['BlobmanRiderGrab']+'\nend)()\n'
        program+='local Legs=(function()\n'+modules['ExplosionLegs']+'\nend)()\nlocal Cadence=(function()\n'+modules['BlobmanCadence']+'\nend)()\n'
        run('source_defense492',program+read('source_defense492_body.luau'))
        main=modules['Main'];a=main.index('tbl12.BreakLimb = function(');b=main.index('tbl12.UpdateWalkSpeed =',a)
        run('leg_native492',read('model_mock.luau')+'\n'+read('leg_native492_body.luau').replace('__ACTUAL_BREAK_LIMB__',main[a:b]))
        a=main.index('tbl12.RequestNativeOwnership=function');b=main.index('tbl12.SNO = function',a)
        run('native_owner492',read('model_mock.luau')+'\n'+read('native_owner492_body.luau').replace('__ACTUAL_REQUEST__',main[a:b]))
        assert 'RemoveLegs=function(valid)return tbl12.BreakLimb(localPlayer,"Legs",valid)end'in main
        assert 'tbl12.BlobmanRiderGrab:SetEnabled(value)'in main
        assert 'Min=0,Max=1000'in main and 'BlobmanCadence:SetDelay(value)'in main
        assert 'return tbl12.FoodRemover:Detach(model,valid)'in main
    if 'AntiKickItems'in modules:
        main=modules['Main'];a=main.index('tbl12.RemoveSticky = function(arg, arg2)');b=main.index('tbl12.BreakLimb =',a)
        body=read('unstick_defense_body.luau').replace('__ACTUAL_UNSTICK__',main[a:b])
        run('unstick_defense',read('model_mock.luau')+'\nlocal Items=(function()\n'+modules['AntiKickItems']+'\nend)()\n'+body)
    assert 'DecoyGucci'not in modules and 'tbl12.DecoyGucci'not in modules['Main'],'Removed YouDecoyGucci still runs'
    for removed in ('Text="Kick Selected"','Text="Kick Server"','Text="Prepare Pallet"','Text="Copy Kick Info"','AddToggle("EKIToggle"','AddDropdown("KickServerMethod"'):
        assert removed not in modules['Main'],('Removed target control remains',removed)
    assert 'selectedPlayers,nil,false,nil,"Select Player"'in modules['Main'],'Target AddToList shortcut remains'
    if 'TargetPanel'in modules:
        run('target_panel488','local Panel=(function()\n'+modules['TargetPanel']+'\nend)()\n'+read('target_panel488_body.luau'))
    if 'TargetPanel'in modules and 'FoodRemover'in modules:
        program=read('model_mock.luau')+'\nlocal Remover=(function()\n'+modules['FoodRemover']+'\nend)()\n'
        program+='local Panel=(function()\n'+modules['TargetPanel']+'\nend)()\n'+read('food_target490_body.luau')
        run('food_target490',program)
    if 'GameShopStyle'in modules:
        run('game_shop484',read('ui_engine_mock.luau')+'\n'+read('ui_native_mock.luau')+'\nlocal Layout=(function()\n'+modules['ShopLayout']+'\nend)()\nlocal Quick=(function()\n'+modules['ShopQuickSpawn']+'\nend)()\nlocal Shop=(function(...)\n'+modules['GameShopStyle']+'\nend)(function(name)if name=="ShopQuickSpawn"then return Quick end;assert(name=="ShopLayout");return Layout end)\n'+read('game_shop484_body.luau'))
    if 'ShopLayout'in modules:
        frame_case=read('game_shop484_body.luau').replace("local pages=Instance.new('Folder',menu)","local pages=Instance.new('Frame',menu)")
        run('game_shop484_frame',read('ui_engine_mock.luau')+'\n'+read('ui_native_mock.luau')+'\nlocal Layout=(function()\n'+modules['ShopLayout']+'\nend)()\nlocal Quick=(function()\n'+modules['ShopQuickSpawn']+'\nend)()\nlocal Shop=(function(...)\n'+modules['GameShopStyle']+'\nend)(function(name)if name=="ShopQuickSpawn"then return Quick end;assert(name=="ShopLayout");return Layout end)\n'+frame_case)
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
        assert 'Enabled=function()return not flag11 and not tbl7.States.DefenseLegRemoval and not tbl8.GucciAntiGrab and tbl8.AntiGrab end'in main
        for token in ('JumpRequest=UserInputService.JumpRequest','tbl12.BlobmanRide:Dismount()','tbl12.PCLDAvatars:SetMode(value)','CatalogRoots=function()','Vector3.new(0,-20,0)'):
            assert token in main,('missing native integration',token)
    if 'PCLDAvatarESP'in modules:
        main=modules['Main'];a=main.index('tbl12.UpdateSmoothPCLD = function(dt)');b=main.index('tbl12.SetSmoothPCLDConnection = function()',a)
        actual_update=main[a:b]
        native='\nlocal Motion=(function()\n'+modules['ESPMotion']+'\nend)()\nlocal function AttachNativeMotion(tbl12,tbl17,tick)\n'+actual_update+'\nend\n'
        run('pcld_avatar',read('model_mock.luau')+'\nlocal Avatars=(function()\n'+modules['PCLDAvatarESP']+'\nend)()\n'+native+read('pcld_avatar_body.luau'))
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
        query_start=modules['Main'].index('ReceiverOverlaps=function(part,receiver)')
        query_end=modules['Main'].index('\n                    MarkerOwned=',query_start)
        receiver_query=modules['Main'][query_start+len('ReceiverOverlaps='):query_end].strip().rstrip(',')
        sweep_prefix=program[:program.index(read('kick_body.luau'if 'PalletStroke'in modules else 'native_pallet_body.luau'))]
        run('pallet_sweep',sweep_prefix+read('pallet_receiver_query_prefix.luau')+'\nlocal ActualReceiverOverlaps='+receiver_query+'\n'+read('pallet_sweep_body.luau'))
        run('source_pallet492',sweep_prefix+read('source_pallet492_body.luau'))
        run('pallet_reaction',read('model_mock.luau')+'\nlocal Reaction=(function()\n'+modules['PalletReaction']+'\nend)()\n'+read('pallet_reaction_body.luau'))
        if 'PalletCadence'in modules:
            run('pallet_cadence','local Cadence=(function()\n'+modules['PalletCadence']+'\nend)()\n'+read('pallet_cadence_body.luau'))
        run('pallet_ownership',read('kick_mock.luau')+'\nlocal Ownership=(function()\n'+modules['PalletOwnership']+'\nend)()\n'+read('pallet_ownership_body.luau'))
        loop_source='\nlocal Handoff=(function()\n'+modules['KickHandoff']+'\nend)()\nlocal Loop=(function(...)\n'+modules['KickLoop']+'\nend)(function(name)assert(name=="KickHandoff");return Handoff end)\n'
        native_context=modules['Main'].split('tbl12.KickLoop=requireModule("KickLoop").Install(',1)[1].split('lib:OnUnload(function()tbl12.KickLoop:Dispose()',1)[0]
        assert 'LowLatency=true'in native_context and 'NativePhases=true'in native_context,'Kick lost its bounded native frame cadence'
        assert 'tbl12.SNO(root,.65,valid,true)'in native_context,'Kick acquisition still accepts a stale owner marker without physical ownership'
        assert 'IntervalSeconds=function()'in native_context and 'KickInterval:CycleSeconds()'in native_context,'Loop MS is not connected to full-cycle timing'
        assert modules['Main'].count('tbl12.KickInterval:BuildUI(')==1,'Loop MS settings are missing or duplicated'
        assert 'tbl12.KickInterval:BuildUI(v21)'in modules['Main'] and 'AddRightGroupbox("Loop MS"'not in modules['Main'],'Loop MS moved outside Kick Settings'
        assert 'Pulsed=false,SourceKick=true'in modules['Main'] and 'KickPulsePause'not in modules['Main'],'Primary kick still uses the discarded pulse/sweep profile'
        assert 'SourceMode=function()return tbl9.NKSourceMode'in native_context and 'tbl12.PalletRagdoll:SourceContact(character,valid)'in native_context
        assert ':Maintain(character,valid)'not in native_context and 'StableHoldBeforeRefresh=true'not in native_context,'Primary kick still waits for the removed sweep/hold gate'
        baseline='\nlocal BaselineLoop=(function(...)\n'+read('kick494_baseline.luau')+'\nend)(function()return Handoff end)\n'
        run('source_kick495',read('kick_mock.luau')+loop_source+baseline+read('source_kick492_body.luau'))
        main=modules['Main'];start=main.index('tbl12.KickLoop=requireModule')
        a=main.index('Collisions=function(character,enabled)',start);b=main.index('\n                Stabilize=',a)
        collision=main[a+len('Collisions='):b].strip().rstrip(',')
        a=main.index('RequestRagdoll=function(character,valid)',start);b=main.index('\n                WarmRagdoll=',a)
        route=main[a+len('RequestRagdoll='):b].strip().rstrip(',')
        a=main.index('OwnershipBusy=function()',start);b=main.index('\n                Grab=',a)
        busy=main[a+len('OwnershipBusy='):b].strip().rstrip(',')
        a=main.index('Stabilize=function(character)',start);b=main.index('\n                Limbs=',a)
        stabilize=main[a+len('Stabilize='):b].strip().rstrip(',')
        body=read('kick_profile494_body.luau').replace('__COLLISIONS__',collision).replace('__ROUTE__',route).replace('__OWNERSHIP_BUSY__',busy).replace('__STABILIZE__',stabilize)
        run('kick_profile494',read('model_mock.luau')+loop_source+body)
        assert 'PreserveCharacterRig=true'in native_context and 'SourceKick=true'in main
        supply_context=main.split('tbl12.PalletSupply=requireModule("PalletSupply").Install(',1)[1].split('tbl12.PalletRagdoll=',1)[0]
        assert supply_context.count('SpawnToy:InvokeServer(')==1 and 'tbl12.SpawnToy('not in supply_context,'Pallet still uses the generic repeating spawner'
        assert 'tbl12.PalletSupply:Get(valid)'in main and 'tbl12.PalletSupply:Dispose()'in main
        run('pallet_supply494',read('kick_mock.luau')+'\n'+read('pallet_supply494_prefix.luau')+'\nlocal Supply=(function()\n'+modules['PalletSupply']+'\nend)()\n'+read('pallet_supply494_body.luau'))
        run('native_contacts494',sweep_prefix+read('native_contacts494_body.luau'))
        run('super_fast495',sweep_prefix+read('super_fast495_body.luau'))

        run('kick_channel',read('kick_mock.luau')+loop_source+read('kick_channel_body.luau'))
        run('kick_handoff',read('kick_mock.luau')+loop_source+read('kick_handoff_body.luau'))
        run('kick_eki',read('kick_mock.luau')+loop_source+read('kick_eki_body.luau'))
        run('kick_interval',read('kick_mock.luau')+loop_source+'\nlocal Interval=(function()\n'+modules['KickInterval']+'\nend)()\n'+read('kick_interval_body.luau'))
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
