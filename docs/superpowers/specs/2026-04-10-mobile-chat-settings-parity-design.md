# Mobile Chat Settings Parity Design

## Context

User requested implementation of mobile `Настройки чатов` aligned with web behavior and visual structure, including presets and upload of custom wallpapers.

Web already stores these settings in `users.chatSettings` and `users.customBackgrounds`. Mobile should use the same data contract.

## Goals

- Add mobile Chat Settings screen with web-equivalent controls.
- Persist settings to the same Firestore fields as web.
- Support custom wallpaper upload and selection on mobile.
- Provide in-screen live preview for bubbles and wallpaper.

## Scope

In scope:

- New route and screen for chat settings.
- Settings controls:
  - bottom nav appearance (`colorful|minimal`)
  - outgoing and incoming bubble colors
  - font size (`small|medium|large`)
  - bubble radius (`rounded|square`)
  - chat wallpaper presets + none
  - custom wallpapers (`customBackgrounds`) with upload/select/remove
  - show timestamps toggle
  - reset settings
- Menu navigation from account sheet to chat settings screen.

Out of scope:

- Full custom bottom-nav icon editor parity (`bottomNavIconNames`, `bottomNavIconGlobalStyle`, `bottomNavIconStyles`) in this phase.
- Rebuilding all web settings pages beyond chat settings.

## Data Model Parity

Use existing user document fields:

- `users/{uid}.chatSettings.bottomNavAppearance`
- `users/{uid}.chatSettings.bubbleColor`
- `users/{uid}.chatSettings.incomingBubbleColor`
- `users/{uid}.chatSettings.fontSize`
- `users/{uid}.chatSettings.bubbleRadius`
- `users/{uid}.chatSettings.chatWallpaper`
- `users/{uid}.chatSettings.showTimestamps`
- `users/{uid}.customBackgrounds` (array of URLs)

No schema changes.

## Selected Approach

Build a dedicated Flutter screen backed by a focused settings service/repository that updates Firestore atomically per user action and supports wallpaper upload via Firebase Storage.

Why:

- Fast parity with web contract.
- Keeps settings logic centralized.
- Minimizes risk of data drift between web and mobile.

## Design

### 1) Navigation and entry point

- Add route: `/settings/chats`.
- In `chat_account_menu_sheet.dart`, make `Настройки чатов` open `/settings/chats`.

### 2) Chat settings screen structure

New screen (suggested path):

- `mobile/app/lib/features/chat/ui/chat_settings_screen.dart`

Sections:

1. Header (`Настройки чатов` + subtitle)
2. `Нижнее меню` (2 selectable cards)
3. `Предпросмотр` (sample messages + timestamps)
4. `Исходящие сообщения` (color chips)
5. `Входящие сообщения` (color chips)
6. `Размер шрифта` (3 segmented options)
7. `Форма пузырьков` (rounded/square preview cards)
8. `Фон чата` (preset tiles incl. `Нет`)
9. `Ваши фоны` (horizontal list + Add tile + delete)
10. `Показывать время` switch
11. `Сбросить настройки`

### 3) Custom wallpaper upload flow

Flow:

1. User taps `Добавить` in `Ваши фоны`.
2. Pick image from gallery.
3. Compress/resize image on-device.
4. Upload to Storage path `wallpapers/{uid}/{timestamp}.jpg`.
5. Get download URL.
6. Append URL to `users/{uid}.customBackgrounds`.
7. Optionally apply immediately as `chatSettings.chatWallpaper`.

Delete behavior:

- Remove URL from `customBackgrounds`.
- If deleted URL equals current `chatWallpaper`, reset `chatWallpaper` to `null`.

### 4) Persistence strategy

- Optimistic local UI update for responsive controls.
- Firestore write per control change (debounced where needed).
- Show inline/snackbar error and rollback local state on failed write.

### 5) Integration with existing chat UI

- Ensure chat render uses latest `chatSettings` values for:
  - bubble colors
  - bubble radius
  - font size
  - timestamps
  - wallpaper

At minimum, this must be reflected in chat preview and in actual chat message rendering on mobile.

## Error Handling

- Upload errors: show destructive snackbar, keep previous wallpaper.
- Firestore write errors: show error and restore previous control value.
- Missing auth user: route back to `/auth`.

## Testing Strategy

1. Static checks
   - `flutter analyze` for touched files.

2. Manual behavior checks
   - Open Chat Settings from avatar menu.
   - Change each setting and verify immediate preview.
   - Restart app and verify settings persisted.
   - Upload custom wallpaper, apply, reopen app, verify URL persists.
   - Remove active custom wallpaper -> fallback wallpaper behavior correct.

3. Regression checks
   - Chat list and chat screen still load without blank states.
   - Account menu `Профиль` and `Выйти` remain functional.

## Acceptance Criteria

- Mobile has `/settings/chats` screen with the requested sections.
- Preset controls and toggles persist to `users.chatSettings`.
- Custom wallpapers can be uploaded, selected, and removed via `customBackgrounds`.
- Chat preview reflects current settings.
- Entry from account menu works and does not break existing auth/chat flows.
