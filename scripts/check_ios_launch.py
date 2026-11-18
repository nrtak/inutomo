"""Verify the iOS app contains Godot's supported single-window launch configuration."""
import plistlib
import sys
from pathlib import Path


def check_scene_configuration(info):
    manifest = info.get("UIApplicationSceneManifest", {})
    scenes = manifest.get("UISceneConfigurations", {}).get("UIWindowSceneSessionRoleApplication", [])
    if not any(scene.get("UISceneConfigurationName") == "Default Configuration" for scene in scenes):
        raise ValueError("Missing iOS application scene configuration. Check the Godot iOS export template.")
    if not (info.get("UILaunchStoryboardName") or info.get("UILaunchStoryboards")
            or isinstance(info.get("UILaunchScreen"), dict) or info.get("UILaunchScreens")):
        raise ValueError("Missing SDK 27 launch screen.")


if __name__ == "__main__":
    check_scene_configuration(plistlib.loads(Path(sys.argv[1]).read_bytes()))
    print("iOS launch screen and window scene configuration verified")
