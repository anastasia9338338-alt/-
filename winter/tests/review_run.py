#!/usr/bin/env python3
"""Run bounded fake-Roblox geometry/lifecycle checks; not a live renderer test."""
from pathlib import Path
import argparse, subprocess, tempfile

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--luau',type=Path,default=Path('/workspace/scratch/astral-speed/tools/luau'))
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    parts=[(root/'tests/review_mock.luau').read_text()]
    names=[name for name in ('Snow','Decor','Weather')if (root/'src'/(name+'.luau')).exists()]
    parts.append('local modules={}\n')
    for name in names:
        parts += [f'modules.{name}=(function()\n',(root/'src'/(name+'.luau')).read_text(),'\nend)()\n']
    parts.append((root/'tests/review_body.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='winter-review-')as temp:
        path=Path(temp)/'modules.luau';path.write_text(''.join(parts))
        result=subprocess.run([str(args.luau),str(path)],capture_output=True,text=True)
        print(result.stdout,end='')
        if result.returncode:print(result.stderr,end='')
        raise SystemExit(result.returncode)

if __name__=='__main__':main()
