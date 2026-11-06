require 'xcodeproj'
require 'tmpdir'
require 'fileutils'

def check(value, message)
  raise message unless value
end

%w[CareFood CareHappy CareEnergy CareClean].each do |name|
  image = File.expand_path("../build/widget-assets/#{name}.png", __dir__)
  width, height = File.binread(image, 24)[16, 8].unpack('NN')
  check(width >= 192 && height >= 192, "#{name} must stay sharp on 3x iPhone displays")
end

Dir.mktmpdir('widget-project-') do |root|
  project_path = File.join(root, 'PuppyIsland.xcodeproj')
  project = Xcodeproj::Project.new(project_path)
  app = project.new_target(:application, 'PuppyIsland', :ios, '15.0')
  FileUtils.mkdir_p(File.join(root, 'PuppyIsland'))
  Xcodeproj::Plist.write_to_path({'CFBundlePackageType' => 'APPL', 'CFBundleShortVersionString' => '0.1.0'}, File.join(root, 'PuppyIsland/Info.plist'))
  Xcodeproj::Plist.write_to_path({'original-entitlement' => true}, File.join(root, 'PuppyIsland/App.entitlements'))
  app.build_configurations.each do |configuration|
    configuration.build_settings['INFOPLIST_FILE'] = 'PuppyIsland/Info.plist'
    configuration.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'PuppyIsland/App.entitlements'
  end
  project.save
  script = File.expand_path('../native/widgets/configure_project.rb', __dir__)
  check(system({'IOS_BUNDLE_ID' => 'com.example.dog', 'IOS_APP_GROUP' => 'group.com.example.dog.shared'}, RbConfig.ruby, script, project_path), 'Widget project configuration failed')
  result = Xcodeproj::Project.open(project_path)
  app = result.targets.find { |target| target.name == 'PuppyIsland' }
  widget = result.targets.find { |target| target.name == 'InushimaWidgets' }
  check(widget && app.dependencies.any? { |dependency| dependency.target == widget }, 'App must build its widget dependency')
  check(app.copy_files_build_phases.any? { |phase| phase.dst_subfolder_spec == '13' && phase.files_references.include?(widget.product_reference) }, 'Widget must be embedded in PlugIns')
  check(widget.source_build_phase.files_references.map(&:path).sort == %w[InushimaWidget.swift WidgetSnapshot.swift], 'Widget compiles both Swift sources')
  check(app.source_build_phase.files_references.any? { |file| file.path == 'WidgetReload.swift' }, 'Native bridge must link WidgetCenter')
  app_entitlements = Xcodeproj::Plist.read_from_path(File.join(root, 'InushimaWidgets/App.entitlements'))
  widget_entitlements = Xcodeproj::Plist.read_from_path(File.join(root, 'InushimaWidgets/Widget.entitlements'))
  check(app_entitlements['original-entitlement'] == true, 'Existing app entitlements must survive')
  check(app_entitlements['com.apple.security.application-groups'] == widget_entitlements['com.apple.security.application-groups'], 'Both targets must share exactly the same App Group')
  check(widget.build_configurations.all? { |configuration| configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] == 'com.example.dog.widget' }, 'Widget must use its own bundle ID')
  check(File.file?(File.join(root, 'InushimaWidgets/Assets.xcassets/PreviewDog.imageset/PreviewDog.png')), 'Widget fallback art must be packaged')
end
puts 'Widget project integration tests passed'
