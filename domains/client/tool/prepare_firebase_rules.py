
#!/usr/bin/env python3
"""Convert the production Firebase RTDB rules file to strict JSON.

The production rules (lib/remote_storage/firebase_realtime_database_rules.json)
contain // comments and literal newlines inside string values, which the
Firebase CLI / RTDB emulator cannot parse. The emulator silently falls back to
fully permissive rules in that case, so this script emits a sanitized copy.

Usage: python3 tool/prepare_firebase_rules.py <src> <dst>
"""
import json
import sys

def sanitize(src: str) -> str:
    out = []
    i = 0
    in_string = False
    while i < len(src):
        c = src[i]
        if in_string:
            if c == '\\':
                out.append(src[i:i + 2])
                i += 2
                continue
            if c == '"':
                in_string = False
                out.append(c)
                i += 1
                continue
            out.append(c if c not in '\n\r\t' else ' ')
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == '/' and i + 1 < len(src) and src[i + 1] == '/':
            while i < len(src) and src[i] != '\n':
                i += 1
            continue
        out.append(c)
        i += 1
    return ''.join(out)

def main() -> None:
    src_path, dst_path = sys.argv[1], sys.argv[2]
    with open(src_path) as f:
        src = f.read()
    rules = json.loads(sanitize(src))
    with open(dst_path, 'w') as f:
        json.dump(rules, f, indent=2)
    print(f'sanitized rules written to {dst_path}')

if __name__ == '__main__':
    main()

