#!/bin/bash
set -euo pipefail
project="$(pwd)"
version="${GODOT_VERSION:-4.5.1}"
work="$RUNNER_TEMP/puppy-reminders"
mkdir -p "$work"
curl --fail --location --retry 3 "https://github.com/godotengine/godot/archive/refs/tags/${version}-stable.tar.gz" -o "$work/godot.tar.gz"
tar -xzf "$work/godot.tar.gz" -C "$work"
source_dir="$work/godot-${version}-stable"
python3 -m venv "$work/venv"
"$work/venv/bin/pip" install scons==4.8.1
cd "$source_dir"
"$work/venv/bin/scons" platform=ios target=template_release arch=arm64 vulkan=no metal=no core/disabled_classes.gen.h core/version_generated.gen.h core/object/gdvirtual.gen.inc
cd "$project"
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos clang++ -std=c++17 -arch arm64 -isysroot "$sdk" -miphoneos-version-min=15.0 -fobjc-arc -fmodules -fcxx-modules -fblocks -fno-exceptions -frtti -O2 -DPTRCALL_ENABLED -DTHREADS_ENABLED -DIOS_ENABLED -DUNIX_ENABLED -DNDEBUG -I"$source_dir" -I"$source_dir/platform/ios" -c native/reminders/puppy_reminders.mm -o "$work/reminders.o"
mkdir -p ios/plugins/PuppyReminders
xcrun libtool -static "$work/reminders.o" -o ios/plugins/PuppyReminders/PuppyReminders.a
cp native/reminders/PuppyReminders.gdip ios/plugins/PuppyReminders/
clang++ -std=c++17 tests/visit_reminder_policy.cpp -o "$work/reminder-policy-test"
"$work/reminder-policy-test"
