import copy
import datetime
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('install_profile', Path(__file__).resolve().parents[1] / 'scripts/install_profile.py')
profiles = importlib.util.module_from_spec(spec)
spec.loader.exec_module(profiles)


class WidgetSigningTests(unittest.TestCase):
    def setUp(self):
        self.now = datetime.datetime(2026, 11, 5, tzinfo=datetime.timezone.utc)
        self.team = 'R3233N87DC'
        self.bundle = 'com.inujima.app'
        self.group = 'group.com.inujima.app.shared'
        self.profile = {
            'TeamIdentifier': [self.team], 'UUID': '00000000-0000-4000-8000-000000000001',
            'ExpirationDate': datetime.datetime(2027, 1, 1),
            'Entitlements': {'application-identifier': self.team + '.' + self.bundle,
                             'com.apple.security.application-groups': [self.group]},
        }

    def validate(self, value, bundle=None):
        return profiles.validate_profile(value, self.team, bundle or self.bundle, self.group, self.now)

    def test_app_and_widget_need_their_own_profiles(self):
        self.validate(self.profile)
        with self.assertRaisesRegex(ValueError, 'must match'):
            self.validate(self.profile, self.bundle + '.widget')
        widget = copy.deepcopy(self.profile)
        widget['Entitlements']['application-identifier'] += '.widget'
        self.validate(widget, self.bundle + '.widget')

    def test_profiles_require_the_shared_app_group(self):
        self.profile['Entitlements'].pop('com.apple.security.application-groups')
        with self.assertRaisesRegex(ValueError, 'regenerate'):
            self.validate(self.profile)

    def test_distribution_and_team_checks(self):
        for change in [dict(TeamIdentifier=['WRONGTEAM00']),
                       dict(ProvisionedDevices=['device']), dict(ProvisionsAllDevices=True),
                       dict(ExpirationDate=datetime.datetime(2025, 1, 1)), dict(UUID='../not-a-profile')]:
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.validate(dict(self.profile, **change))
        self.profile['Entitlements']['get-task-allow'] = True
        with self.assertRaisesRegex(ValueError, 'distribution'):
            self.validate(self.profile)

    def test_export_maps_profiles_without_overriding_widget_id(self):
        options = profiles.export_options(self.team, self.bundle, 'app-profile', 'widget-profile')
        self.assertEqual(options['provisioningProfiles'], {
            self.bundle: 'app-profile', self.bundle + '.widget': 'widget-profile'})
        self.assertEqual(options['method'], 'app-store-connect')


if __name__ == '__main__':
    unittest.main()
