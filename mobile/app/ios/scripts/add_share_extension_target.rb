#!/usr/bin/env ruby
# Idempotent: adds ShareExtension app-extension target to Runner.xcodeproj.
#
# Что делает:
#   1. Регистрирует группу `ShareExtension` в дереве проекта (если ещё нет).
#   2. Создаёт references на ShareViewController.swift / Info.plist /
#      ShareExtension.entitlements / MainInterface.storyboard.
#   3. Создаёт PBXNativeTarget типа `:app_extension` (если ещё нет).
#   4. Прописывает build settings (bundle id, App Group entitlements,
#      deployment target, swift, dev team).
#   5. Делает Runner depend-on extension и встраивает .appex в
#      PBXCopyFilesBuildPhase('Embed Foundation Extensions').
#
# Запуск (idempotent):
#   ruby ios/scripts/add_share_extension_target.rb
#
# Re‑запуск после ручных правок в Xcode не должен ничего испортить —
# скрипт сначала ищет существующие сущности и не создаёт дубликатов.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
EXT_NAME = 'ShareExtension'
EXT_BUNDLE_ID = 'com.lighchat.lighchatMobile.ShareExtension'
APP_GROUP_ID = 'group.com.lighchat.lighchatMobile'
DEV_TEAM = 'T896C2B2FW'
DEPLOYMENT = '15.0'
SWIFT_VERSION = '5.0'

abort "Project not found at #{PROJECT_PATH}" unless File.exist?(PROJECT_PATH)
project = Xcodeproj::Project.open(PROJECT_PATH)

# ---------- 1. Group + file refs ----------
group = project.main_group[EXT_NAME] || project.main_group.new_group(EXT_NAME, EXT_NAME)

def find_or_add_ref(group, name)
  ref = group.files.find { |f| f.path == name || f.display_name == name }
  ref || group.new_reference(name)
end

swift_ref = find_or_add_ref(group, 'ShareViewController.swift')
plist_ref = find_or_add_ref(group, 'Info.plist')
ent_ref   = find_or_add_ref(group, 'ShareExtension.entitlements')
sb_ref    = find_or_add_ref(group, 'MainInterface.storyboard')

# Info.plist в группе должен быть отмечен с file_type 'text.plist.xml'
plist_ref.last_known_file_type = 'text.plist.xml'
ent_ref.last_known_file_type   = 'text.plist.entitlements'

# ---------- 2. Target ----------
target = project.targets.find { |t| t.name == EXT_NAME }
unless target
  target = project.new_target(:app_extension, EXT_NAME, :ios, DEPLOYMENT)
  # new_target не всегда правильно проставляет product_type для extension
  target.product_type = 'com.apple.product-type.app-extension'
end

# ---------- 3. Build settings ----------
target.build_configurations.each do |config|
  bs = config.build_settings
  bs['INFOPLIST_FILE'] = "#{EXT_NAME}/Info.plist"
  bs['CODE_SIGN_ENTITLEMENTS'] = "#{EXT_NAME}/ShareExtension.entitlements"
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = EXT_BUNDLE_ID
  bs['DEVELOPMENT_TEAM'] = DEV_TEAM
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT
  bs['SWIFT_VERSION'] = SWIFT_VERSION
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['SKIP_INSTALL'] = 'YES'
  bs['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  bs['CLANG_ENABLE_MODULES'] = 'YES'
  bs['CURRENT_PROJECT_VERSION'] = '1'
  bs['MARKETING_VERSION'] = '1.0'
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['DEFINES_MODULE'] = 'YES'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
end

# ---------- 4. Sources / resources ----------
sources_phase = target.source_build_phase
unless sources_phase.files_references.include?(swift_ref)
  sources_phase.add_file_reference(swift_ref)
end
resources_phase = target.resources_build_phase
unless resources_phase.files_references.include?(sb_ref)
  resources_phase.add_file_reference(sb_ref)
end

# ---------- 5. Runner depends + embed ----------
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner target not found' unless runner

unless runner.dependencies.any? { |d| d.target == target }
  runner.add_dependency(target)
end

# Find or create PBXCopyFilesBuildPhase('Embed Foundation Extensions') in Runner.
embed_phase = runner.copy_files_build_phases.find do |p|
  p.symbol_dst_subfolder_spec == :plug_ins ||
    p.dst_subfolder_spec.to_s == '13' ||
    (p.name || '').include?('Embed Foundation Extensions')
end
unless embed_phase
  embed_phase = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
end

product_ref = target.product_reference
unless embed_phase.files_references.include?(product_ref)
  bf = embed_phase.add_file_reference(product_ref)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts "OK: #{EXT_NAME} target ensured (bundle=#{EXT_BUNDLE_ID})."
