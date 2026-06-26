#!/usr/bin/env ruby
# Setup TodayWidget target in the Xcode project
require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
main_target = project.targets.find { |t| t.name == 'Runner' }

# Check if widget target already exists
if project.targets.any? { |t| t.name == 'TodayWidget' }
  puts "TodayWidget target already exists."
  project.save
  exit 0
end

# Create widget extension target
widget_target = project.new_target(
  :app_extension,
  'TodayWidget',
  :ios,
  '13.0'
)

widget_target.product_name = 'TodayWidget'

# Add source files
sources = [
  'ios/TodayWidget/TodayWidget.swift',
  'ios/TodayWidget/TodayWidgetBundle.swift',
]

sources.each do |src|
  file_ref = project.main_group.new_file(src)
  widget_target.source_build_phase.add_file_reference(file_ref)
end

# Add widget extension frameworks
%w[WidgetKit.framework SwiftUI.framework].each do |framework|
  widget_target.frameworks_build_phase.add_file_reference(
    project.frameworks_group.new_file("System/Library/Frameworks/#{framework}")
  )
end

# Info.plist
widget_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'ios/TodayWidget/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.course.manager.TodayWidget'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
end

# Add widget extension to main target's dependencies
main_target.add_dependency(widget_target)

# Embed app extension
embed_phase = main_target.copy_files_build_phases.find { |p| p.dst_subfolder_spec == '13' } ||
  main_target.new_copy_files_build_phase('Embed App Extensions')

embed_phase.dst_path = '$(EXTENSIONS_FOLDER_PATH)'
embed_phase.dst_subfolder_spec = '13'

embed_ref = project.products_group.children.find { |p| p.name == 'TodayWidget.appex' } ||
  project.products_group.new_product_ref_for_target('TodayWidget', 'com.course.manager.TodayWidget')

embed_phase.add_file_reference(embed_ref)

# Add App Groups capability
[main_target, widget_target].each do |target|
  target.build_configurations.each do |config|
    entitlements = config.build_settings['CODE_SIGN_ENTITLEMENTS'] || 'Runner/TodayWidget.entitlements'
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = entitlements
    config.build_settings['DEVELOPMENT_TEAM'] = ''
  end
end

project.save
puts "TodayWidget target setup complete!"
