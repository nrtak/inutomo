import base64
import datetime
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys


def profile_folders():
    return [Path.home() / folder for folder in (
        'Library/MobileDevice/Provisioning Profiles',
        'Library/Developer/Xcode/UserData/Provisioning Profiles',
    )]


def main():
    root = Path(os.environ['RUNNER_TEMP'])
    source = root / 'inutomo.mobileprovision'
    options = root / 'ExportOptions.plist'
    if '--clean' in sys.argv:
        source.unlink(missing_ok=True)
        options.unlink(missing_ok=True)
        uuid = os.environ.get('PROFILE_UUID')
        if uuid:
            for folder in profile_folders():
                (folder / (uuid + '.mobileprovision')).unlink(missing_ok=True)
        return
    source.write_bytes(base64.b64decode(os.environ['PROFILE_BASE64'], validate=True))
    source.chmod(0o600)
    decoded = subprocess.run(['security', 'cms', '-D', '-i', str(source)],
                             check=True, capture_output=True).stdout
    profile = plistlib.loads(decoded)
    team = os.environ['TEAM_ID']
    bundle = os.environ['BUNDLE_ID']
    entitlements = profile['Entitlements']
    checks = [
        (profile['TeamIdentifier'] == [team], 'Provisioning profile has the wrong Apple team'),
        (entitlements['application-identifier'] == team + '.' + bundle, 'Provisioning profile must match ' + bundle),
        (not entitlements.get('get-task-allow', False), 'Use a distribution profile'),
        ('ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices', False), 'Use an App Store distribution profile'),
        (profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Provisioning profile has expired'),
    ]
    for valid, error in checks:
        if not valid:
            raise ValueError(error)
    uuid = profile['UUID']
    for folder in profile_folders():
        folder.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, folder / (uuid + '.mobileprovision'))
    with open(os.environ['GITHUB_ENV'], 'a') as env:
        env.write('PROFILE_UUID=' + uuid + '\n')
    options.write_bytes(plistlib.dumps(dict(
        method='app-store-connect', signingStyle='manual', teamID=team,
        provisioningProfiles={bundle: uuid}, uploadSymbols=True,
    )))


if __name__ == '__main__':
    main()
