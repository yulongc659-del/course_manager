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
  'TodayWidget/TodayWidget.swift',
  'TodayWidget/TodayWidgetBundle.swift',
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
  config.build_settings['INFOPLIST_FILE'] = 'TodayWidget/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.course.manager.TodayWidget'
  config.build_settings['PRODUCT_NAME'] = 'TodayWidget'
  config.build_settings['PRODUCT_MODULE_NAME'] = 'TodayWidget'
  config.build_settings['EXECUTABLE_NAME'] = 'TodayWidget'
  config.build_settings['WRAPPER_EXTENSION'] = 'appex'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = ''
end

# Add WidgetKit.framework to main target (weak link)
widget_ref = project.frameworks_group.new_file("System/Library/Frameworks/WidgetKit.framework")
build_file = main_target.frameworks_build_phase.add_file_reference(widget_ref)
build_file.settings = { 'ATTRIBUTES' => ['Weak'] }

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
