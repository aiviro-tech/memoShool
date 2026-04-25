# -*- coding: utf-8 -*-
import glob, sys

sys.stdout.reconfigure(encoding='utf-8')

# Focused patch: remaining corrupted sequences still found after first pass
extra_replacements = [
    ('\u00c3\u2030',      '\u00c9'),   # Ã‰  -> É  (U+00c3 U+2030 in the file as read UTF-8)
    ('\u00c3\u02c6',      '\u00c6'),   # ÃŽ  -> Æ  (just in case)
    ('\u00c3\u02c6',      '\u00c8'),   # fallback
    # The file bytes are: 0xC3 0x89 stored as latin-1 in an UTF-8 file
    # When Python reads the file as UTF-8, 0xC3 0x89 -> Ã\x89 (two chars in unicode)
    # Let's use the literal chars that appear after the first-pass failed:
    # 'Ã‰' is U+00C3 + U+2030 (‰) as seen by utf-8 reader of a cp1252 stored file
    # But more reliably: let's just do a bytes-level fix
]

def fix_file(filepath):
    with open(filepath, 'rb') as f:
        raw = f.read()

    # Detect if file has double-encoded sequences.
    # The pattern: file was originally UTF-8, saved as latin-1/cp1252, then re-read as UTF-8
    # C3 89 in the stored bytes -> should be C3 89 (É in UTF-8) but stored as C3 C2 89 or similar
    # 
    # The simplest fix: decode as latin-1, then encode as utf-8 bytes, decode again as utf-8
    # But only for files that have the mojibake pattern.
    #
    # The mojibake pattern: C3 A9 stored in file -> when decoded as UTF-8 gives 'Ã©' (two code points)
    # This means the file was: original bytes were C3 A9 (UTF-8 for é),
    # but those bytes were re-interpreted as latin-1: C3='Ã' A9='©' -> then stored again as UTF-8.
    # So stored bytes are: C3 83 C2 A9 (UTF-8 for Ã and ©)
    #
    # Let's try: decode stored bytes as utf-8, then encode as latin-1, then decode as utf-8

    try:
        text = raw.decode('utf-8')
    except UnicodeDecodeError:
        print(f'SKIP (not utf-8): {filepath}')
        return False

    original_text = text

    # Re-encode as latin-1 then decode as utf-8 to undo the double-encoding
    try:
        fixed = text.encode('latin-1', errors='ignore').decode('utf-8', errors='ignore')
    except Exception:
        fixed = text

    # Only accept the fix if it actually changed the content and the result is reasonable
    # (i.e., no replacement chars introduced)
    if fixed != text and '\ufffd' not in fixed:
        # Check that it actually fixed the specific known patterns
        if any(bad in text for bad in ['Ã©', 'Ã¨', 'Ã ', 'Ã§', 'Ã‰', 'Ã¨', 'â€™', 'â€¢']):
            with open(filepath, 'w', encoding='utf-8') as out:
                out.write(fixed)
            return True

    return False

files = glob.glob('**/*.dart', recursive=True)
fixed = []
for f in files:
    if fix_file(f):
        fixed.append(f)
        print(f'Fixed: {f}')

if not fixed:
    print('No files needed fixing (or fix was not safe to apply).')
else:
    print(f'\nTotal files fixed: {len(fixed)}')
