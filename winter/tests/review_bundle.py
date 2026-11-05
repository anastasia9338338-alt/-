#!/usr/bin/env python3
"""Run startup/restoration scenarios against the actual packaged winter.lua."""
from pathlib import Path
import argparse,subprocess,tempfile

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--luau',type=Path,default=Path('/workspace/scratch/astral-speed/tools/luau'))
    args=parser.parse_args();root=Path(__file__).resolve().parents[1]
    prefix=(root/'tests/review_mock.luau').read_text()+'\nlocal modules={}\n'+(root/'tests/review_main_setup.luau').read_text()
    program=prefix+'\nlocal function runMain(...)\n'+(root.parent/'winter.lua').read_text()+'\nend\n'+(root/'tests/review_main_body.luau').read_text()
    with tempfile.TemporaryDirectory(prefix='winter-bundle-')as temp:
        p=Path(temp)/'bundle.luau';p.write_text(program)
        r=subprocess.run([str(args.luau),str(p)],capture_output=True,text=True)
        print(r.stdout,end='')
        if r.returncode:print(r.stderr,end='')
        raise SystemExit(r.returncode)

if __name__=='__main__':main()
