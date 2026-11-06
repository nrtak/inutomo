#!/bin/bash
set -euo pipefail
version="${GODOT_VERSION:-4.5.1}"
source_dir="$RUNNER_TEMP/puppy-reminders/godot-${version}-stable"
work="$RUNNER_TEMP/puppy-widgets"
mkdir -p "$work"
test -f "$source_dir/core/object/gdvirtual.gen.inc"
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos clang++ -std=c++17 -arch arm64 -isysroot "$sdk" -miphoneos-version-min=15.0 -fobjc-arc -fmodules -fcxx-modules -fblocks -fno-exceptions -frtti -O2 -DPTRCALL_ENABLED -DTHREADS_ENABLED -DIOS_ENABLED -DUNIX_ENABLED -DNDEBUG -I"$source_dir" -I"$source_dir/platform/ios" -c native/widgets/puppy_widgets.mm -o "$work/widgets.o"
mkdir -p ios/plugins/PuppyWidgets
xcrun libtool -static "$work/widgets.o" -o ios/plugins/PuppyWidgets/PuppyWidgets.a
cp native/widgets/PuppyWidgets.gdip ios/plugins/PuppyWidgets/
cp tests/widget_snapshot.swift "$work/main.swift"
swiftc native/widgets/WidgetSnapshot.swift "$work/main.swift" -o "$work/widget-snapshot-test"
"$work/widget-snapshot-test" build/widget-assets/snapshot-fixture.json
gem install --user-install xcodeproj --version 1.27.0 --no-document
ruby tests/widget_project.rb
