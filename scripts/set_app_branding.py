import argparse
import plistlib
import re
import zipfile
from pathlib import Path

NAME = 'Inushima'

def branded_plist(data):
    info = plistlib.loads(data)
    if info.get('CFBundlePackageType') != 'APPL':
        return None
    info['CFBundleDisplayName'] = NAME
    info['CFBundleName'] = NAME
    return plistlib.dumps(info, fmt=plistlib.FMT_XML)

def branded_strings(data):
    text = data.decode('utf-8-sig')
    return re.sub(r'(CFBundle(?:DisplayName|Name)\s*=\s*)"[^"]*"', lambda match: match[1] + '"' + NAME + '"', text).encode('utf-8')

def apply(ios, macos):
    updated = 0
    for path in ios.rglob('*Info.plist'):
        result = branded_plist(path.read_bytes())
        if result is not None:
            path.write_bytes(result)
            updated += 1
    if updated != 1:
        raise RuntimeError('Expected exactly one iOS application Info.plist')
    for path in ios.rglob('InfoPlist.strings'):
        path.write_bytes(branded_strings(path.read_bytes()))
    temporary = macos.with_suffix('.branding.zip')
    updated = 0
    with zipfile.ZipFile(macos) as source, zipfile.ZipFile(temporary, 'w') as target:
        for entry in source.infolist():
            data = source.read(entry)
            if entry.filename.endswith('.app/Contents/Info.plist'):
                result = branded_plist(data)
                if result is not None:
                    data = result
                    updated += 1
            elif entry.filename.endswith('InfoPlist.strings'):
                data = branded_strings(data)
            target.writestr(entry, data)
    if updated != 1:
        temporary.unlink()
        raise RuntimeError('Expected exactly one macOS application Info.plist')
    temporary.replace(macos)
    print('Apple app display names set to Inushima')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ios', type=Path, required=True)
    parser.add_argument('--macos', type=Path, required=True)
    args = parser.parse_args()
    apply(args.ios, args.macos)
