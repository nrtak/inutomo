require 'xcodeproj'
require 'fileutils'
require 'json'

project_path = File.expand_path(ARGV.fetch(0))
project = Xcodeproj::Project.open(project_path)
app = project.targets.find { |target| target.product_type == 'com.apple.product-type.application' }
raise 'Expected one containing app' unless app
raise 'Widget target already exists' if project.targets.any? { |target| target.name == 'InushimaWidgets' }
root = File.dirname(project_path)
source = File.join(root, 'InushimaWidgets')
FileUtils.mkdir_p(source)
bundle = ENV.fetch('IOS_BUNDLE_ID', ENV.fetch('BUNDLE_ID', 'com.inujima.app'))
group_id = ENV.fetch('IOS_APP_GROUP', "group.#{bundle}.shared")
team = ENV.fetch('APPLE_TEAM_ID', ENV.fetch('TEAM_ID', 'R3233N87DC'))
raise 'Invalid application group' unless group_id.match?(/\Agroup\.[A-Za-z0-9.-]+\z/)

%w[WidgetSnapshot.swift InushimaWidget.swift WidgetReload.swift].each do |name|
  FileUtils.cp(File.join(__dir__, name), File.join(source, name))
end
assets = File.join(source, 'Assets.xcassets')
FileUtils.mkdir_p(assets)
File.write(File.join(assets, 'Contents.json'), JSON.generate(info: {version: 1, author: 'xcode'}))
%w[PreviewDog CareFood CareHappy CareEnergy CareClean].each do |name|
  target = File.join(assets, "#{name}.imageset")
  FileUtils.mkdir_p(target)
  FileUtils.cp(File.join(__dir__, '../../build/widget-assets', "#{name}.png"), target)
  File.write(File.join(target, 'Contents.json'), JSON.generate(
    images: [{filename: "#{name}.png", idiom: 'universal'}],
    info: {version: 1, author: 'xcode'}, properties: {'preserves-vector-representation': false}))
end

app_info_setting = app.build_configurations.first.build_settings.fetch('INFOPLIST_FILE')
resolve = ->(path) { File.expand_path(path.gsub('$(SRCROOT)', root).gsub('${SRCROOT}', root).delete('"'), root) }
app_info_path = resolve.call(app_info_setting)
app_info = Xcodeproj::Plist.read_from_path(app_info_path)
app_info['InushimaAppGroup'] = group_id
Xcodeproj::Plist.write_to_path(app_info, app_info_path)

info = {
  'CFBundleDisplayName' => 'Inushima', 'CFBundleName' => 'InushimaWidgets',
  'CFBundleIdentifier' => '$(PRODUCT_BUNDLE_IDENTIFIER)', 'CFBundleExecutable' => '$(EXECUTABLE_NAME)',
  'CFBundlePackageType' => 'XPC!', 'CFBundleInfoDictionaryVersion' => '6.0',
  'CFBundleShortVersionString' => app_info.fetch('CFBundleShortVersionString', '0.1.0'),
  'CFBundleVersion' => '$(CURRENT_PROJECT_VERSION)', 'InushimaAppGroup' => group_id,
  'NSExtension' => {'NSExtensionPointIdentifier' => 'com.apple.widgetkit-extension'}
}
Xcodeproj::Plist.write_to_path(info, File.join(source, 'Info.plist'))
entitlement_key = 'com.apple.security.application-groups'
Xcodeproj::Plist.write_to_path({entitlement_key => [group_id]}, File.join(source, 'Widget.entitlements'))
app_entitlements_setting = app.build_configurations.first.build_settings['CODE_SIGN_ENTITLEMENTS']
existing_path = resolve.call(app_entitlements_setting) if app_entitlements_setting && !app_entitlements_setting.empty?
app_entitlements = existing_path && File.file?(existing_path) ? Xcodeproj::Plist.read_from_path(existing_path) : {}
app_entitlements[entitlement_key] = (Array(app_entitlements[entitlement_key]) + [group_id]).uniq
Xcodeproj::Plist.write_to_path(app_entitlements, File.join(source, 'App.entitlements'))

widget = project.new_target(:app_extension, 'InushimaWidgets', :ios, '17.0')
files = project.main_group.new_group('InushimaWidgets', 'InushimaWidgets')
widget.add_file_references(%w[WidgetSnapshot.swift InushimaWidget.swift].map { |name| files.new_file(name) })
widget.resources_build_phase.add_file_reference(files.new_file('Assets.xcassets'))
app.add_file_references([files.new_file('WidgetReload.swift')])
app.add_dependency(widget)
embed = app.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
embedded = embed.add_file_reference(widget.product_reference)
embedded.settings = {'ATTRIBUTES' => ['RemoveHeadersOnCopy']}
build_number = ENV.fetch('GITHUB_RUN_NUMBER', '1')
app.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings['SWIFT_VERSION'] = '5.0'
  settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'InushimaWidgets/App.entitlements'
  settings['PROVISIONING_PROFILE_SPECIFIER'] = '$(INUSHIMA_APP_PROFILE)'
  settings['DEVELOPMENT_TEAM'] = team
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle
  settings['CURRENT_PROJECT_VERSION'] = build_number
end
widget.build_configurations.each do |configuration|
  configuration.build_settings.merge!({
    'SWIFT_VERSION' => '5.0', 'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'PRODUCT_BUNDLE_IDENTIFIER' => bundle + '.widget', 'PRODUCT_NAME' => '$(TARGET_NAME)',
    'INFOPLIST_FILE' => 'InushimaWidgets/Info.plist', 'GENERATE_INFOPLIST_FILE' => 'NO',
    'CODE_SIGN_ENTITLEMENTS' => 'InushimaWidgets/Widget.entitlements',
    'CODE_SIGN_STYLE' => 'Manual', 'DEVELOPMENT_TEAM' => team,
    'PROVISIONING_PROFILE_SPECIFIER' => '$(INUSHIMA_WIDGET_PROFILE)',
    'CURRENT_PROJECT_VERSION' => build_number, 'MARKETING_VERSION' => '0.1.0',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES', 'SKIP_INSTALL' => 'YES',
    'TARGETED_DEVICE_FAMILY' => '1', 'SUPPORTS_MACCATALYST' => 'NO',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
    'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS' => 'NO'
  })
end
attributes = project.root_object.attributes['TargetAttributes'] ||= {}
[app, widget].each do |target|
  attributes[target.uuid] ||= {}
  attributes[target.uuid]['SystemCapabilities'] ||= {}
  attributes[target.uuid]['SystemCapabilities']['com.apple.ApplicationGroups.iOS'] = {'enabled' => 1}
end
project.save
puts 'Installed Inushima small and medium widget extension'
