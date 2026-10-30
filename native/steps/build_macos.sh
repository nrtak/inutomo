#!/bin/bash
set -euo pipefail
project="$(pwd)"
work="$RUNNER_TEMP/puppy-pedometer"
mkdir -p "$work"
curl --fail --location --retry 3 "https://github.com/godotengine/godot/archive/refs/tags/4.5.1-stable.tar.gz" -o "$work/godot.tar.gz"
tar -xzf "$work/godot.tar.gz" -C "$work"
source_dir="$work/godot-4.5.1-stable"
python3 -m venv "$work/venv"
"$work/venv/bin/pip" install scons==4.8.1
cd "$source_dir"
"$work/venv/bin/scons" platform=ios target=template_release arch=arm64 vulkan=no metal=no  core/disabled_classes.gen.h core/version_generated.gen.h core/object/gdvirtual.gen.inc
cd "$project"
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos clang++ -std=c++17 -arch arm64 -isysroot "$sdk"  -miphoneos-version-min=14.0 -fobjc-arc -fmodules -fcxx-modules -fblocks  -fno-exceptions -frtti -O2 -DPTRCALL_ENABLED -DTHREADS_ENABLED  -DIOS_ENABLED -DUNIX_ENABLED -DNDEBUG -I"$source_dir" -I"$source_dir/platform/ios"  -c native/steps/puppy_pedometer.mm -o "$work/pedometer.o"
mkdir -p ios/plugins/PuppyPedometer
xcrun libtool -static "$work/pedometer.o" -o ios/plugins/PuppyPedometer/PuppyPedometer.a
cp native/steps/PuppyPedometer.gdip ios/plugins/PuppyPedometer/
