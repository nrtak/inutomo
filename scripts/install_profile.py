import base64
import datetime
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import uuid as uuid_module


def profile_folders():
    return [Path.home() / folder for folder in (
        'Library/MobileDevice/Provisioning Profiles',
        'Library/Developer/Xcode/UserData/Provisioning Profiles',
    )]


def validate_profile(profile, team, bundle, group, now=None):
    entitlements = profile['Entitlements']
    now = now or datetime.datetime.now(datetime.timezone.utc)
    expiration = profile['ExpirationDate'].replace(tzinfo=datetime.timezone.utc)
    checks = [
        (profile['TeamIdentifier'] == [team], 'Provisioning profile has the wrong Apple team'),
        (entitlements['application-identifier'] == team + '.' + bundle, 'Provisioning profile must match ' + bundle),
        (not entitlements.get('get-task-allow', False), 'Use a distribution profile'),
        ('ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices', False), 'Use an App Store distribution profile'),
        (expiration > now, 'Provisioning profile has expired'),
        (group in entitlements.get('com.apple.security.application-groups', []),
         'Enable App Groups for ' + bundle + ' and regenerate its distribution profile with ' + group),
    ]
    for valid, error in checks:
        if not valid:
            raise ValueError(error)
    uuid_module.UUID(profile['UUID'])
    return profile['UUID']


def export_options(team, bundle, app_uuid, widget_uuid):
    return dict(method='app-store-connect', signingStyle='manual', teamID=team,
                provisioningProfiles={bundle: app_uuid, bundle + '.widget': widget_uuid}, uploadSymbols=True)


def main():
    root = Path(os.environ['RUNNER_TEMP'])
    options = root / 'ExportOptions.plist'
    sources = [root / 'inutomo.mobileprovision', root / 'inutomo-widget.mobileprovision']
    if '--clean' in sys.argv:
        for source in sources:
            source.unlink(missing_ok=True)
        options.unlink(missing_ok=True)
        for key in ['PROFILE_UUID', 'WIDGET_PROFILE_UUID']:
            identifier = os.environ.get(key)
            if identifier:
                uuid_module.UUID(identifier)
                for folder in profile_folders():
                    (folder / (identifier + '.mobileprovision')).unlink(missing_ok=True)
        return
    team = os.environ['TEAM_ID']
    bundle = os.environ['BUNDLE_ID']
    group = os.environ.get('IOS_APP_GROUP') or 'group.' + bundle + '.shared'
    uuids = []
    # Validate both before installing either profile. Never print signing data.
    for source, key, identifier in zip(sources, ['PROFILE_BASE64', 'WIDGET_PROFILE_BASE64'], [bundle, bundle + '.widget']):
        source.write_bytes(base64.b64decode(os.environ[key], validate=True))
        source.chmod(0o600)
        decoded = subprocess.run(['security', 'cms', '-D', '-i', str(source)],
                                 check=True, capture_output=True).stdout
        uuids.append(validate_profile(plistlib.loads(decoded), team, identifier, group))
    for source, identifier in zip(sources, uuids):
        for folder in profile_folders():
            folder.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, folder / (identifier + '.mobileprovision'))
    with open(os.environ['GITHUB_ENV'], 'a') as env:
        env.write('PROFILE_UUID=' + uuids[0] + '\nWIDGET_PROFILE_UUID=' + uuids[1] + '\n')
    options.write_bytes(plistlib.dumps(export_options(team, bundle, *uuids)))


if __name__ == '__main__':
    main()
