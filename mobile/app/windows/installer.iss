; Inno Setup installer script для LighChat Windows.
;
; Генерирует .exe installer, который:
;   * Ставит приложение в %ProgramFiles% (или %LOCALAPPDATA% если без admin).
;   * Создаёт shortcut в Start Menu (всегда) и опционально на Desktop.
;   * Регистрируется в «Установка и удаление программ» (с uninstaller).
;   * Поддерживает custom URI scheme `lighchat://` для deep links.
;
; Сборка: ISCC.exe windows/installer.iss /DAppVersion=1.0.0
; Запуск из CI см. .github/workflows/desktop.yml.

#define MyAppName "LighChat"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#define MyAppPublisher "LighChat"
#define MyAppURL "https://github.com/ShpantsevVyacheslav/LighChat"
#define MyAppExeName "lighchat_mobile.exe"

[Setup]
AppId={{B3F4A6C1-2B0A-4F8E-9F3D-7C5D6E1A8B40}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=LighChat-windows-installer
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; lowest: ставит в %LOCALAPPDATA% без admin prompt'а. С опцией allowed
; пользователь может выбрать system-wide install (если запустит as admin).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Только x64 — Flutter Windows release собирается под x64 (нет ARM64).
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "launchatstartup"; Description: "Запускать LighChat при старте Windows"; GroupDescription: "Дополнительно:"; Flags: unchecked

[Files]
; Копируем ВСЁ содержимое Flutter release bundle: lighchat_mobile.exe,
; flutter_windows.dll, plugins/, data/ и так далее.
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Custom URI scheme handler: `lighchat://chat/<id>` будет открывать
; приложение. Используется для deep links из браузера / других приложений.
Root: HKCU; Subkey: "Software\Classes\lighchat"; ValueType: string; ValueName: ""; ValueData: "URL:LighChat Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\lighchat"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\lighchat\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\lighchat\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

; Автозапуск (опционально, через таск launchatstartup).
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue; Tasks: launchatstartup

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
