#!/usr/bin/env python3
"""Backward-compatibility check for Firebase RTDB rules.

Compares the NEW rules (working copy) against the OLD rules (base branch by
default) by replaying a canonical set of client operations against both rule
sets in a local RTDB emulator.

An operation that was allowed by the old rules but is denied by the new rules
is a backward-compatibility break -> exit code 1.
An operation that was denied before and is allowed now is reported as a
"relaxed" warning (not a failure).

Prerequisites: node/npm with `firebase-tools` installed (`npm i -g firebase-tools`).

Usage:
  python3 tool/check_rules_backward_compatibility.py [--new RULES] [--old RULES]
      [--base GIT_REF] [--project NS] [--port PORT]

Environment:
  FIREBASE_TOOLS - firebase binary (default: firebase)
"""
import argparse
import base64
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CLIENT_DIR = os.path.dirname(HERE)
DEFAULT_RULES = os.path.join(
    CLIENT_DIR, 'lib', 'remote_storage', 'firebase_realtime_database_rules.json')
WORK_DIR = os.path.join(CLIENT_DIR, '.dart_tool', 'firebase_rules_compat')

sys.path.insert(0, HERE)
from prepare_firebase_rules import sanitize  # noqa: E402


# --- Canonical client operations ---------------------------------------------
# Each op: (name, method, path, body_or_None). Paths are relative to the DB root
# and mirror what lib/remote_storage/firebase_realtime_database.dart writes/reads.
OPERATIONS = [
    ('read_model', 'GET', 'models/m1', None),
    ('read_registry_metadata', 'GET', 'registries/r1/metadata', None),
    ('read_registry_transactions', 'GET', 'registries/r1/transactions', None),
    ('create_registry', 'PATCH', '',
     {'registries/r1/metadata': {'id': 'r1'}}),
    ('create_first_model_with_transaction', 'PATCH', '',
     {'models/m1': {'id': 'm1', 'registryId': 'r1'},
      'registries/r1/lastIdx': 0,
      'registries/r1/transactions/0': {
          'id': '0', 'prevId': '', 'originatorId': 'u1',
          'changes': {'m1': True}}}),
    ('append_transaction_and_model', 'PATCH', '',
     {'models/m2': {'id': 'm2', 'registryId': 'r1'},
      'registries/r1/lastIdx': 1,
      'registries/r1/transactions/1': {
          'id': '1', 'prevId': '0', 'originatorId': 'u1',
          'changes': {'m2': True}}}),
    ('link_child_model', 'PATCH', '',
     {'registries/r1/lastIdx': 2,
      'registries/r1/transactions/2': {
          'id': '2', 'prevId': '1', 'originatorId': 'u1',
          'changes': {'m1': True, 'c1': True}},
      'models/c1': {'id': 'c1', 'registryId': 'r1',
                    'parents': {'m1': True}},
      'models/m1/children/c1': True}),
    ('update_model_field', 'PATCH', '',
     {'registries/r1/lastIdx': 3,
      'registries/r1/transactions/3': {
          'id': '3', 'prevId': '2', 'originatorId': 'u1',
          'changes': {'m1': True}},
      'models/m1/field1': 'value1'}),
    ('delete_model', 'PATCH', '', {'models/m1': None}),
]


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def forged_token(email: str = 'user@a.aa') -> str:
    """Unsigned JWT accepted by the RTDB emulator (signature is not checked)."""
    header = {'alg': 'none', 'typ': 'JWT'}
    payload = {'sub': 'testuser', 'email': email, 'email_verified': True,
               'iat': int(time.time()), 'exp': int(time.time()) + 3600}
    return f'{b64url(json.dumps(header).encode())}.' \
           f'{b64url(json.dumps(payload).encode())}.'


def get_old_rules_from_git(base_ref: str) -> str:
    repo_root = subprocess.run(
        ['git', '-C', CLIENT_DIR, 'rev-parse', '--show-toplevel'],
        capture_output=True, text=True, check=True).stdout.strip()
    rel = os.path.relpath(DEFAULT_RULES, repo_root)
    r = subprocess.run(['git', '-C', CLIENT_DIR, 'show', f'{base_ref}:{rel}'],
                       capture_output=True, text=True, check=True)
    return r.stdout


def start_emulator(port: int, initial_rules: str) -> subprocess.Popen:
    os.makedirs(WORK_DIR, exist_ok=True)
    with open(os.path.join(WORK_DIR, 'rules.json'), 'w') as f:
        f.write(sanitize(initial_rules))
    with open(os.path.join(WORK_DIR, 'firebase.json'), 'w') as f:
        json.dump({'database': {'rules': 'rules.json'},
                   'emulators': {'database': {'port': port},
                                 'hub': {'port': port + 100},
                                 'ui': {'enabled': False}}}, f)
    firebase = os.environ.get('FIREBASE_TOOLS',
                              shutil.which('firebase') or 'firebase')
    proc = subprocess.Popen(
        [firebase, 'emulators:start', '--only', 'database',
         '--project', 'rules-compat-test'],
        cwd=WORK_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
    for _ in range(90):
        # 1. Проверяем, не упал ли процесс Firebase в фоне
        if proc.poll() is not None:
            raise RuntimeError(f"Firebase CLI неожиданно завершил работу с кодом {proc.returncode}. Возможно, занят порт или кривой JSON.")

        # 2. Пытаемся достучаться до эмулятора
        try:
            urllib.request.urlopen(
                f'http://127.0.0.1:{port}/.json?ns=rules-compat-test',
                timeout=2)
            return proc
        except urllib.error.HTTPError:
            # emulator is up; HTTP error comes from rules, which is fine
            return proc
        except Exception:
            time.sleep(1)

    proc.terminate()
    raise RuntimeError('RTDB emulator failed to start')


def put_rules(port: int, rules_src: str) -> None:
    rules = sanitize(rules_src)
    json.loads(rules)  # fail fast on unparseable rules
    with open(os.path.join(WORK_DIR, 'rules.json'), 'w') as f:
        f.write(rules)
    url = (f'http://127.0.0.1:{port}/.settings/rules.json'
           f'?ns=rules-compat-test')
    req = urllib.request.Request(url, data=rules.encode(), method='PUT',
                                 headers={'Authorization': 'Bearer owner'})
    urllib.request.urlopen(req, timeout=10).read()


def run_operation(port: int, method: str, path: str, body, token: str) -> bool:
    url = f'http://127.0.0.1:{port}/{path}.json?ns=rules-compat-test&auth={token}'
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    try:
        urllib.request.urlopen(req, timeout=10).read()
        return True
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            return False
        raise


def evaluate_rules(port: int, rules_src: str, token: str):
    put_rules(port, rules_src)
    # fresh database state per rules version
    req = urllib.request.Request(
        f'http://127.0.0.1:{port}/.json?ns=rules-compat-test', data=b'',
        method='DELETE', headers={'Authorization': 'Bearer owner'})
    urllib.request.urlopen(req, timeout=10).read()
    results = {}
    for name, method, path, body in OPERATIONS:
        results[name] = run_operation(port, method, path, body, token)
    return results


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--new', default=DEFAULT_RULES)
    ap.add_argument('--old', default=None,
                    help='Path to old rules; defaults to --base git ref')
    ap.add_argument('--base', default='origin/main',
                    help='Git ref to take old rules from (default: origin/main)')
    ap.add_argument('--port', type=int, default=9100)
    args = ap.parse_args()

    with open(args.new) as f:
        new_src = f.read()
    if args.old:
        with open(args.old) as f:
            old_src = f.read()
    else:
        old_src = get_old_rules_from_git(args.base)

    emulator = start_emulator(args.port, old_src)
    try:
        token = forged_token()
        old_res = evaluate_rules(args.port, old_src, token)
        new_res = evaluate_rules(args.port, new_src, token)
    finally:
        emulator.terminate()
        try:
            emulator.wait(timeout=10)
        except subprocess.TimeoutExpired:
            emulator.kill()

    print(f'{"operation":<38} {"old":<10} {"new":<10} verdict')
    breaks = relaxed = 0
    for name, _, _, _ in OPERATIONS:
        o, n = old_res[name], new_res[name]
        fmt = lambda r: 'allowed' if r else 'denied'
        if o and not n:
            verdict, breaks = 'BREAK', breaks + 1
        elif n and not o:
            verdict, relaxed = 'relaxed', relaxed + 1
        else:
            verdict = 'ok'
        print(f'{name:<38} {fmt(o):<10} {fmt(n):<10} {verdict}')

    if breaks:
        print(f'\nFAIL: {breaks} backward-compatibility break(s). '
              'New rules deny operations allowed by the old rules.')
        return 1
    print(f'\nOK: no backward-compatibility breaks'
          + (f' ({relaxed} operation(s) relaxed)' if relaxed else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
