

#!/usr/bin/env python3
"""Deploy the production Firebase RTDB rules.

Reads the service account key from the CLOSERS_FIREBASE_SERVICE_ACCOUNT_JSON
environment variable (or from a line KEY=VALUE in a .env file passed via
--env-file), sanitizes the production rules with prepare_firebase_rules.sanitize
and runs `firebase deploy --only database`.

The project id is taken from the service account key (project_id field) unless
CLOSERS_PROJECT_ID is set.

Usage: python3 tool/deploy_firebase_rules.py [--env-file .env]
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prepare_firebase_rules import sanitize  # noqa: E402

CLIENT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES_PATH = os.path.join(
    CLIENT_DIR, 'lib', 'remote_storage',
    'firebase_realtime_database_rules.json')


def load_env_file(path: str) -> dict:
    env = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, _, value = line.partition('=')
            env[key.strip()] = value.strip().strip('"').strip("'")
    return env


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--env-file', default=None,
                    help='Optional .env file with '
                         'CLOSERS_FIREBASE_SERVICE_ACCOUNT_JSON=...')
    ap.add_argument('--project', default=None,
                    help='Firebase project id (default: project_id from the '
                         'service account key or CLOSERS_PROJECT_ID)')
    args = ap.parse_args()

    sa_json = os.environ.get('CLOSERS_FIREBASE_SERVICE_ACCOUNT_JSON')
    if not sa_json and args.env_file:
        sa_json = load_env_file(args.env_file).get(
            'CLOSERS_FIREBASE_SERVICE_ACCOUNT_JSON')
    if not sa_json:
        print('ERROR: CLOSERS_FIREBASE_SERVICE_ACCOUNT_JSON is not set '
              '(environment or --env-file)', file=sys.stderr)
        return 2

    try:
        sa = json.loads(sa_json)
    except json.JSONDecodeError as e:
        print(f'ERROR: service account key is not valid JSON: {e}',
              file=sys.stderr)
        return 2

    project = args.project or os.environ.get('CLOSERS_PROJECT_ID') \
        or sa.get('project_id')
    if not project:
        print('ERROR: cannot determine the Firebase project id', file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory(prefix='rtdb-deploy-') as tmp:
        sa_path = os.path.join(tmp, 'service-account.json')
        with open(sa_path, 'w') as f:
            f.write(sa_json)
        os.chmod(sa_path, 0o600)

        rules_path = os.path.join(tmp, 'rules.json')
        with open(RULES_PATH) as f:
            rules_src = f.read()
        with open(rules_path, 'w') as f:
            f.write(sanitize(rules_src))

        firebase_json_path = os.path.join(tmp, 'firebase.json')
        with open(firebase_json_path, 'w') as f:
            json.dump({'database': {'rules': os.path.basename(rules_path)}}, f)

        env = dict(os.environ)
        env['GOOGLE_APPLICATION_CREDENTIALS'] = sa_path
        firebase = shutil.which('firebase') or 'npx'
        cmd = ([firebase, 'deploy', '--only', 'database',
               '--project', project, '--config', firebase_json_path]
               if firebase != 'npx' else
               ['npx', 'firebase-tools', 'deploy', '--only', 'database',
                '--project', project, '--config', firebase_json_path])
        print(f'Deploying RTDB rules to project {project} ...')
        result = subprocess.run(cmd, cwd=tmp, env=env)
        if result.returncode != 0:
            print('ERROR: firebase deploy failed', file=sys.stderr)
            return result.returncode
    print('OK: RTDB rules deployed')
    return 0


if __name__ == '__main__':
    sys.exit(main())

