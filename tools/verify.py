#!/usr/bin/env python3
"""Check the exact standalone bundle, embedded code, API calls and ZIP."""
from pathlib import Path
import argparse, concurrent.futures, re, shutil, subprocess, tempfile, zipfile
from regressions import check_regressions
from feature_checks import run_feature_checks

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--luau-dir',type=Path)
    parser.add_argument('--analysis-dir',type=Path,help='Keep full analyzer diagnostics here for review')
    args=parser.parse_args()
    repo=Path(__file__).resolve().parents[1]
    def binary(name):
        path=str(args.luau_dir/name)if args.luau_dir else shutil.which(name)
        if not path or not Path(path).is_file():raise SystemExit(f'Missing {name}; pass --luau-dir pointing to official Luau CLI tools')
        return path
    compiler,runner,analyzer=binary('luau-compile'),binary('luau'),binary('luau-analyze')
    source=(repo/'astral.lua').read_text()
    pattern=re.compile(r'^sources\.(\w+) = \[========\[\n(.*?)\n\]========\]',re.M|re.S)
    matches=pattern.findall(source);modules=dict(matches)
    assert len(matches)==len(modules)and {'Main','Bootstrap','Notices','ExtraFeatures'}<=modules.keys()
    for name,body in modules.items():
        for dependency in re.findall(r'requireModule\(["\'](\w+)["\']\)',body):
            assert dependency in modules,(name,'missing module',dependency)
    # Catch obsolete calls such as CancelWarm when a controller is replaced.
    bindings=dict(re.findall(r'tbl12\.(\w+)\s*=\s*requireModule\(["\'](\w+)["\']\)\.(?:Install|new)',modules['Main']))
    for alias,module in bindings.items():
        declared=set(re.findall(r'function\s+\w+[:.](\w+)\s*\(',modules[module]))
        declared|=set(re.findall(r'\b(\w+)\s*=\s*function\s*\(',modules[module]))
        for caller,body in modules.items():
            for call in re.findall(r'tbl12\.'+re.escape(alias)+r':(\w+)\s*\(',body):
                assert call in declared,(caller,alias,'missing method',call)
    embedded=re.search(r'local embeddedGameplay = \[====\[(.*?)\]====\]',modules['ExtraFeatures'],re.S)
    assert embedded,'embedded gameplay missing'
    with tempfile.TemporaryDirectory(prefix='astral-check-')as temp:
        folder=Path(temp)
        files=[repo/'astral.lua']
        probe=repo/'diagnostics/hit_probe.lua'
        if probe.is_file():files.append(probe)
        for name,body in modules.items():
            if name=='Notices':continue
            path=folder/(name+'.luau');path.write_text(body);files.append(path)
        path=folder/'embedded.luau';path.write_text(embedded[1]);files.append(path)
        def compile_file(path):
            result=subprocess.run([compiler,'--null',str(path)],capture_output=True,text=True)
            assert result.returncode==0,(path.name,result.stdout,result.stderr)
        with concurrent.futures.ThreadPoolExecutor(max_workers=4)as pool:list(pool.map(compile_file,files))
        def analyze_file(path):
            result=subprocess.run([analyzer,'--formatter=plain',str(path)],capture_output=True,text=True,timeout=60)
            log=result.stdout+result.stderr
            if args.analysis_dir:
                args.analysis_dir.mkdir(parents=True,exist_ok=True)
                (args.analysis_dir/(path.stem+'.txt')).write_text(log)
            # Roblox and executor globals are absent from the standalone CLI.
            # Review those diagnostics; don't count them as clean typechecking.
            assert 'SyntaxError:'not in log,(path.name,log)
            assert 'UninitializedLocal:'not in log,(path.name,log)
            if path.stem in {'Main','embedded'}:
                for name in re.findall(r"Unknown global '([^']+)'",log):
                    assert not re.fullmatch(r'(?:v|tbl|fn|flag|n)\d+',name),(path.name,'unresolved local',name)
                    assert name not in {'train','inPlot','inOwnedPlot','Character','_at_refreshRainbow','_abanaRunning'},(path.name,'obsolete global',name)
            if 'TheWorstUIV2'in modules and path.stem in {'Library','TheWorstUIV2','Presentation','Watermark'}:
                allowed={'game','workspace','Enum','Color3','ColorSequence','ColorSequenceKeypoint','NumberSequence','NumberSequenceKeypoint',
                    'UDim','UDim2','Vector2','Vector3','Font','TweenInfo','Instance','task','tick','warn','gethui'}
                unknown=set(re.findall(r"Unknown global '([^']+)'",log))-allowed
                assert not unknown,(path.name,'unresolved UI globals',sorted(unknown))
            return len(log.splitlines())
        with concurrent.futures.ThreadPoolExecutor(max_workers=4)as pool:
            diagnostic_lines=sum(pool.map(analyze_file,[p for p in files if p!=repo/'astral.lua']))
        print(f'ANALYSIS: {diagnostic_lines} diagnostic lines for review (includes missing Roblox definitions and inference limits)')
        check_regressions(modules,embedded[1],runner,folder)
        run_feature_checks(modules,runner,folder)
    with zipfile.ZipFile(repo/'astral.zip')as archive:
        assert archive.namelist()==['astral.lua']and archive.testzip()is None
        assert archive.read('astral.lua')==(repo/'astral.lua').read_bytes(),'ZIP contains another Lua revision'
    if probe.is_file():
        with zipfile.ZipFile(probe.with_suffix('.zip'))as archive:
            assert archive.namelist()==[probe.name]and archive.testzip()is None
            assert archive.read(probe.name)==probe.read_bytes(),'Hit probe ZIP contains another Lua revision'
        print('PASS: standalone receiving-account probe compiles and ZIP matches Lua')
    print(f'PASS: bundle, {len(modules)-1} executable modules, embedded gameplay, {len(bindings)} controller bindings and ZIP')

if __name__=='__main__':main()
