#!/usr/bin/env ruby
# Idempotent reverse of `add_share_extension_target.rb`.
#
# Зачем нужен: бесплатный Apple Developer (Personal Team) НЕ поддерживает
# capability App Groups, без которой `receive_sharing_intent` на iOS не
# работает. Чтобы проект продолжал собираться/подписываться на free
# аккаунте, временно убираем target ShareExtension, его dependency на
# Runner, embed‑phase entry и file reference на .appex продукт.
#
# Что НЕ удаляется (специально, чтобы можно было вернуть в один
# `add_share_extension_target.rb`):
#   - физические файлы `ios/ShareExtension/*` (Swift, Info.plist,
#     entitlements, storyboard);
#   - сам скрипт `add_share_extension_target.rb`;
#   - PBXGroup `ShareExtension` в дереве проекта (он просто ссылается на
#     файлы выше; пустая или с references группа Xcode не мешает).
#
# Запуск:
#   ruby ios/scripts/remove_share_extension_target.rb
#
# Чтобы вернуть всё назад (когда появится paid Apple Developer):
#   ruby ios/scripts/add_share_extension_target.rb

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
EXT_NAME = 'ShareExtension'

abort "Project not found at #{PROJECT_PATH}" unless File.exist?(PROJECT_PATH)
project = Xcodeproj::Project.open(PROJECT_PATH)

target = project.targets.find { |t| t.name == EXT_NAME }
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner target not found' unless runner

if target.nil?
  puts "OK: target #{EXT_NAME} already absent."
else
  product_ref = target.product_reference

  # 1. Убрать .appex из embed-phase Runner.
  runner.copy_files_build_phases.each do |phase|
    phase.files.dup.each do |bf|
      next unless bf.file_ref == product_ref
      phase.remove_build_file(bf)
    end
  end

  # 2. Убрать зависимость Runner -> ShareExtension.
  runner.dependencies.dup.each do |dep|
    next unless dep.target == target
    dep.remove_from_project
  end

  # 3. Удалить product reference (.appex в Products group).
  if product_ref
    product_ref.build_files.dup.each(&:remove_from_project)
    product_ref.remove_from_project
  end

  # 4. Удалить сам target.
  target.remove_from_project

  puts "OK: target #{EXT_NAME} removed (files in ios/#{EXT_NAME}/ kept)."
end

project.save
