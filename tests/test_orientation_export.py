import importlib.util
import plistlib
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('branding', Path(__file__).resolve().parents[1] / 'scripts/set_app_branding.py')
branding = importlib.util.module_from_spec(spec)
spec.loader.exec_module(branding)

class OrientationExportTests(unittest.TestCase):
    def test_iphone_and_ipad_support_both_orientations(self):
        source = plistlib.dumps({'CFBundlePackageType':'APPL', 'UISupportedInterfaceOrientations':['UIInterfaceOrientationLandscapeLeft']})
        result = plistlib.loads(branding.branded_plist(source, ios=True))
        for key in ('UISupportedInterfaceOrientations','UISupportedInterfaceOrientations~ipad'):
            self.assertEqual(len(result[key]),4)
            self.assertIn('UIInterfaceOrientationPortrait', result[key])
            self.assertIn('UIInterfaceOrientationLandscapeLeft', result[key])
            self.assertIn('UIInterfaceOrientationLandscapeRight', result[key])

    def test_macos_and_extensions_keep_their_own_settings(self):
        source = plistlib.dumps({'CFBundlePackageType':'APPL'})
        self.assertNotIn('UISupportedInterfaceOrientations',plistlib.loads(branding.branded_plist(source)))
        extension = plistlib.dumps({'CFBundlePackageType':'XPC!'})
        self.assertIsNone(branding.branded_plist(extension, ios=True))

if __name__=='__main__': unittest.main()
