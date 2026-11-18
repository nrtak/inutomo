import unittest

from scripts.check_ios_launch import check_scene_configuration


class IOSLaunchTests(unittest.TestCase):
    def setUp(self):
        self.info = {
            "UILaunchStoryboardName": "Launch Screen",
            "UIApplicationSceneManifest": {
                "UISceneConfigurations": {
                    "UIWindowSceneSessionRoleApplication": [
                        {"UISceneConfigurationName": "Default Configuration"}
                    ]
                }
            },
        }

    def test_scene_and_launch_screen(self):
        check_scene_configuration(self.info)
        del self.info["UILaunchStoryboardName"]
        self.info["UILaunchScreen"] = {}
        check_scene_configuration(self.info)

    def test_legacy_app_delegate_only_build(self):
        del self.info["UIApplicationSceneManifest"]
        with self.assertRaisesRegex(ValueError, "scene configuration"):
            check_scene_configuration(self.info)

    def test_missing_game_window(self):
        self.info["UIApplicationSceneManifest"]["UISceneConfigurations"] = {}
        with self.assertRaisesRegex(ValueError, "scene configuration"):
            check_scene_configuration(self.info)

    def test_missing_launch_screen(self):
        self.info["UILaunchStoryboardName"] = ""
        with self.assertRaisesRegex(ValueError, "launch screen"):
            check_scene_configuration(self.info)
