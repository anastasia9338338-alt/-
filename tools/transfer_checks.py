"""Verify the replacement controllers from the exact delivered Lua bundle."""
from pathlib import Path
import subprocess

def run_transfer_checks(modules,runner,folder):
    support=Path(__file__).resolve().parent/'feature_tests'
    def read(name):return(support/name).read_text()
    def run(name,program):
        path=Path(folder)/(name+'.luau');path.write_text(program)
        result=subprocess.run([str(runner),str(path)],capture_output=True,text=True)
        assert result.returncode==0,(name,result.stdout,result.stderr)
        print(result.stdout.strip())
    prefix=read('kick_mock.luau')+'\nlocal Pallet\n'+read('reference_kick_prefix.luau')
    ownership='local Ownership=(function()\n'+modules['PalletOwnership']+'\nend)()\n'
    controller=ownership+'Pallet=(function(...)\n'+modules['PalletRagdoll']+'\nend)(function(name)assert(name=="PalletOwnership");return Ownership end)\n'
    run('reference_pallet',prefix+'\n'+controller+read('reference_pallet_body.luau'))
    run('reference_remover',prefix+'\nlocal Remover=(function()\n'+modules['ReferenceAntiKick']+'\nend)()\n'+read('reference_remover_body.luau'))
    loop_source='\nlocal Handoff=(function()\n'+modules['KickHandoff']+'\nend)()\nlocal Loop=(function(...)\n'+modules['KickLoop']+'\nend)(function(name)assert(name=="KickHandoff");return Handoff end)\n'
    run('reference_cycles',prefix+controller+loop_source+read('reference_cycles_body.luau'))
    run('reference_panel',prefix+controller+'local Panel=(function()\n'+modules['TargetPanel']+'\nend)()\n'+read('reference_panel_body.luau'))
    run('pallet_ownership',read('kick_mock.luau')+ownership+read('pallet_ownership_body.luau'))
    for name in ('kick_channel','kick_handoff','kick_eki'):
        run(name,read('kick_mock.luau')+loop_source+read(name+'_body.luau'))
    main=modules['Main'];start=main.index('tbl12.SNO = function');end=main.index('tbl12.RNO = function',start)
    run('pallet_sno',read('kick_mock.luau')+'\n'+read('pallet_sno_prefix.luau')+'\n'+main[start:end]+'\n'+read('pallet_sno_body.luau'))
