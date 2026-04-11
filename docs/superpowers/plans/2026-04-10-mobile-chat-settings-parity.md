# Mobile Chat Settings Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement mobile `Настройки чатов` with web-parity controls and custom wallpaper upload using existing Firestore/Storage fields.

**Architecture:** Add a dedicated Flutter screen (`/settings/chats`) with local editable state hydrated from `users/{uid}`. Persist each control via Firestore patches to `chatSettings`, and use Storage + `customBackgrounds` for user wallpapers. Connect entry point from avatar account menu and ensure preview + chat rendering consume the same setting values.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Firebase Auth, Firestore, Firebase Storage.

---

### Task 1: Add chat settings route and menu navigation

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart`
- Modify: `mobile/app/lib/app_router.dart`
- Create: `mobile/app/lib/features/chat/ui/chat_settings_screen.dart`

- [ ] **Step 1: Add route stub for `/settings/chats`**

```dart
GoRoute(
  path: '/settings/chats',
  builder: (context, state) => const ChatSettingsScreen(),
),
```

- [ ] **Step 2: Add navigation action from account menu**

```dart
item(
  icon: Icons.chat_bubble_outline_rounded,
  title: 'Настройки чатов',
  onTap: onChatSettingsTap,
),
```

And pass callback from `chat_list_screen.dart`:

```dart
onChatSettingsTap: () {
  Navigator.of(ctx).pop();
  context.go('/settings/chats');
},
```

- [ ] **Step 3: Create `ChatSettingsScreen` scaffold**

```dart
class ChatSettingsScreen extends ConsumerWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки чатов')),
      body: const Center(child: Text('Настройки чатов')),
    );
  }
}
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/app_router.dart lib/features/chat/ui/chat_account_menu_sheet.dart lib/features/chat/ui/chat_settings_screen.dart`
Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/app_router.dart mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart mobile/app/lib/features/chat/ui/chat_settings_screen.dart
git commit -m "feat(mobile): add chat settings route and menu entry"
```

### Task 2: Create settings data layer (read/write chatSettings and customBackgrounds)

**Files:**
- Create: `mobile/app/lib/features/chat/data/chat_settings_repository.dart`
- Modify: `mobile/app/lib/app_providers.dart`

- [ ] **Step 1: Add repository API and implementation**

```dart
class ChatSettingsRepository {
  ChatSettingsRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<Map<String, dynamic>?> loadUserSettings(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.data()?.cast<String, dynamic>();
  }

  Future<void> patchChatSettings(String uid, Map<String, Object?> patch) async {
    await _firestore.collection('users').doc(uid).set({'chatSettings': patch}, SetOptions(merge: true));
  }

  Future<void> setChatSettings(String uid, Map<String, Object?> value) async {
    await _firestore.collection('users').doc(uid).set({'chatSettings': value}, SetOptions(merge: true));
  }

  Future<String> uploadWallpaper(String uid, Uint8List bytes) async {
    final ref = _storage.ref('wallpapers/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
```

- [ ] **Step 2: Add providers**

```dart
final chatSettingsRepositoryProvider = Provider<ChatSettingsRepository>((ref) {
  return ChatSettingsRepository();
});
```

- [ ] **Step 3: Add simple parser defaults in provider layer**

```dart
const defaultChatSettings = <String, Object?>{
  'fontSize': 'medium',
  'bubbleColor': null,
  'incomingBubbleColor': null,
  'chatWallpaper': null,
  'bubbleRadius': 'rounded',
  'showTimestamps': true,
  'bottomNavAppearance': 'colorful',
};
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/features/chat/data/chat_settings_repository.dart lib/app_providers.dart`
Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/features/chat/data/chat_settings_repository.dart mobile/app/lib/app_providers.dart
git commit -m "feat(mobile): add chat settings repository and providers"
```

### Task 3: Build full Chat Settings UI sections and preview

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_settings_screen.dart`

- [ ] **Step 1: Add local editable state model in screen**

```dart
class _EditableChatSettings {
  String fontSize;
  String bubbleRadius;
  bool showTimestamps;
  String bottomNavAppearance;
  String? bubbleColor;
  String? incomingBubbleColor;
  String? chatWallpaper;
  List<String> customBackgrounds;
  _EditableChatSettings(...);
}
```

- [ ] **Step 2: Render sections matching spec**

Implement widgets for:

```dart
_BottomNavAppearanceSection
_PreviewSection
_BubbleColorSection(outgoing: true)
_BubbleColorSection(outgoing: false)
_FontSizeSection
_BubbleRadiusSection
_WallpaperPresetSection
_CustomWallpapersSection
_ShowTimestampsSection
_ResetSection
```

- [ ] **Step 3: Wire controls to local state + save action**

For each control update local state immediately, then call:

```dart
await repo.patchChatSettings(uid, {
  'fontSize': state.fontSize,
  'bubbleRadius': state.bubbleRadius,
  'showTimestamps': state.showTimestamps,
  'bottomNavAppearance': state.bottomNavAppearance,
  'bubbleColor': state.bubbleColor,
  'incomingBubbleColor': state.incomingBubbleColor,
  'chatWallpaper': state.chatWallpaper,
});
```

- [ ] **Step 4: Add reset button behavior**

```dart
await repo.setChatSettings(uid, defaultChatSettings);
```

- [ ] **Step 5: Run analyzer and commit**

Run: `flutter analyze lib/features/chat/ui/chat_settings_screen.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_settings_screen.dart
git commit -m "feat(mobile): implement chat settings UI and preview"
```

### Task 4: Implement custom wallpaper upload/select/remove

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_settings_screen.dart`
- Modify: `mobile/app/lib/features/chat/data/chat_settings_repository.dart`

- [ ] **Step 1: Add image picker + compression utilities**

Use existing project utilities if present; otherwise use package flow:

```dart
final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920);
if (picked == null) return;
final bytes = await picked.readAsBytes();
```

- [ ] **Step 2: Upload wallpaper and append URL to `customBackgrounds`**

```dart
final url = await repo.uploadWallpaper(uid, bytes);
await FirebaseFirestore.instance.collection('users').doc(uid).set({
  'customBackgrounds': FieldValue.arrayUnion([url]),
}, SetOptions(merge: true));
```

- [ ] **Step 3: Select and remove custom wallpaper**

Select:

```dart
await repo.patchChatSettings(uid, {'chatWallpaper': url});
```

Remove:

```dart
await FirebaseFirestore.instance.collection('users').doc(uid).set({
  'customBackgrounds': FieldValue.arrayRemove([url]),
  if (state.chatWallpaper == url) 'chatSettings': {'chatWallpaper': null},
}, SetOptions(merge: true));
```

- [ ] **Step 4: Add error handling and progress UI**

Show loading indicator on upload tile and snackbar on failure.

- [ ] **Step 5: Analyze and commit**

Run: `flutter analyze lib/features/chat/ui/chat_settings_screen.dart lib/features/chat/data/chat_settings_repository.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_settings_screen.dart mobile/app/lib/features/chat/data/chat_settings_repository.dart
git commit -m "feat(mobile): add custom chat wallpaper upload and management"
```

### Task 5: Hook settings into mobile chat rendering

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`

- [ ] **Step 1: Read `chatSettings` for current user**

Add provider read and parsed values (font size, bubble radius, colors, wallpaper, timestamps).

- [ ] **Step 2: Apply settings in message bubbles**

Use mapped values in message rendering widgets.

- [ ] **Step 3: Apply wallpaper and timestamps behavior**

Wallpaper in chat background and `showTimestamps` toggle in message metadata visibility.

- [ ] **Step 4: Validate visually via preview parity**

Ensure screen changes reflect selected settings immediately.

- [ ] **Step 5: Analyze and commit**

Run: `flutter analyze lib/features/chat/ui/chat_screen.dart lib/features/chat/ui/chat_list_screen.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/lib/features/chat/ui/chat_list_screen.dart
git commit -m "feat(mobile): apply chat settings to chat rendering"
```

### Task 6: Docs sync and final verification

**Files:**
- Modify: `docs/arcitecture/01-codebase-map.md`
- Modify: `docs/arcitecture/04-runtime-flows.md`

- [ ] **Step 1: Update codebase map docs**

Add `chat_settings_screen.dart` and settings repository responsibilities.

- [ ] **Step 2: Update runtime flow docs**

Describe mobile flow: account menu -> `/settings/chats` -> Firestore `chatSettings` / `customBackgrounds` updates.

- [ ] **Step 3: Run full analyzer for mobile app**

Run: `flutter analyze`

- [ ] **Step 4: Manual validation checklist**

```text
1) Open account menu -> Настройки чатов
2) Change colors/font/radius/timestamps -> preview updates and persists
3) Upload custom wallpaper -> appears in “Ваши фоны” and can be applied
4) Delete active custom wallpaper -> fallback works
5) Open chat screen -> settings reflected in real messages
```

- [ ] **Step 5: Commit docs/final adjustments**

```bash
git add docs/arcitecture/01-codebase-map.md docs/arcitecture/04-runtime-flows.md
git commit -m "docs: sync mobile chat settings flow and module map"
```
