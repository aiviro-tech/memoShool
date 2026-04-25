# -*- coding: utf-8 -*-
import glob, sys

sys.stdout.reconfigure(encoding='utf-8')

files = glob.glob('**/*.dart', recursive=True)
found = False
for f in files:
    with open(f, encoding='utf-8', errors='replace') as fh:
        for i, line in enumerate(fh, 1):
            if 'Ã' in line or '\u00e2\u0080' in line or '\u00c2\u00a0' in line:
                print(f'{f}:{i}: {line.rstrip()}')
                found = True
if not found:
    print('CLEAN - No corrupted characters found!')
