#!/usr/bin/env python3
"""Exercise Main with fake client services; no actual renderer/server involved."""
from pathlib import Path
import argparse, subprocess, tempfile

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--luau',type=Path,default=Path('/workspace/scratch/astral-speed/tools/luau'))
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    parts=[(root/'tests/review_mock.luau').read_text()]
    parts.append('local modules={}\n')
    for name in ('Snow','Decor','Weather'):
        parts += [f'modules.{name}=(function()\n',(root/'src'/(name+'.luau')).read_text(),'\nend)()\n']
    parts.append((root/'tests/review_main_setup.luau').read_text())
    parts+=['local function runMain(...)\n',(root/'src/Main.luau').read_text(),'\nend\n']
    parts.append((root/'tests/review_main_body.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='winter-main-')as temp:
        path=Path(temp)/'main.luau';path.write_text(''.join(parts))
        result=subprocess.run([str(args.luau),str(path)],capture_output=True,text=True)
        print(result.stdout,end='')
        if result.returncode:print(result.stderr,end='')
        raise SystemExit(result.returncode)

if __name__=='__main__':main()
