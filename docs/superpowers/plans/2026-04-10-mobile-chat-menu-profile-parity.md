# Mobile Chat Menu Profile Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix blank chat landing after auth, add avatar account menu in bottom nav, and implement a functional mobile profile page with save/cancel behavior.

**Architecture:** Stabilize chat list screen state-machine first so authenticated users always see either chat content or explicit empty/error state. Then add a reusable account-menu bottom sheet triggered by avatar in bottom nav. Finally add `/profile` route and profile editing screen using existing validators, phone mask utilities, and firebase service layer.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Firebase Auth/Firestore, flutter_test.

---

### Task 1: Stabilize Chat List Non-Blank States

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`

- [ ] **Step 1: Write failing widget test for non-blank fallback**

```dart
testWidgets('shows explicit fallback when conversation list is empty', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('TODO'))));
  expect(find.text('Новая'), findsNothing);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/widget_test.dart`
Expected: FAIL baseline placeholder test.

- [ ] **Step 3: Implement explicit empty-state branch**

In `chat_list_screen.dart`, ensure that when conversations/index are empty, UI renders:

```dart
return Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Пока нет чатов'),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () => context.go('/chats/new'),
        child: const Text('Новая'),
      ),
    ],
  ),
);
```

- [ ] **Step 4: Ensure unknown profile status does not blank/block chats**

Keep existing guard semantics:

```dart
if (status == RegistrationProfileStatus.incomplete) {
  context.go('/auth/google-complete');
  return _bootLoading('Проверка профиля…', uid: user.uid);
}
```

For `unknown`, continue to chats data flow (no hard block screen).

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_list_screen.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_list_screen.dart
git commit -m "fix(mobile): prevent blank chat landing and show explicit empty state"
```

### Task 2: Add Avatar Entry In Bottom Nav

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_bottom_nav.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`
- Create: `mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart`

- [ ] **Step 1: Write failing smoke test for avatar nav action**

```dart
testWidgets('bottom nav shows avatar action', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
  expect(find.byIcon(Icons.account_circle_rounded), findsNothing);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/widget_test.dart`
Expected: FAIL baseline placeholder.

- [ ] **Step 3: Add avatar slot + callback in nav**

Change `ChatBottomNav` API to accept callbacks and avatar:

```dart
class ChatBottomNav extends StatelessWidget {
  const ChatBottomNav({
    super.key,
    required this.onProfileTap,
    this.avatarUrl,
    this.title,
  });

  final VoidCallback onProfileTap;
  final String? avatarUrl;
  final String? title;
}
```

Right-most item becomes avatar button invoking `onProfileTap`.

- [ ] **Step 4: Wire open-sheet action from `chat_list_screen.dart`**

On profile tap:

```dart
showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (_) => ChatAccountMenuSheet(...),
);
```

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_bottom_nav.dart lib/features/chat/ui/chat_list_screen.dart lib/features/chat/ui/chat_account_menu_sheet.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_bottom_nav.dart mobile/app/lib/features/chat/ui/chat_list_screen.dart mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart
git commit -m "feat(mobile): add avatar entry and account menu sheet in bottom nav"
```

### Task 3: Implement Account Menu Actions

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart`
- Modify: `mobile/app/lib/app_providers.dart`

- [ ] **Step 1: Render menu rows matching requested structure**

Rows: `Профиль`, `Настройки чатов`, `Администрирование`, `Уведомления`, `Конфиденциальность`, `Тема · Авто`, `Выйти`.

- [ ] **Step 2: Wire functional rows**

```dart
onProfileTap: () => context.go('/profile');
onSignOutTap: () async {
  await repo.signOut();
  if (context.mounted) context.go('/auth');
}
```

- [ ] **Step 3: Keep non-functional rows explicit**

For non-implemented rows show disabled style and snack/toast: `Скоро`.

- [ ] **Step 4: Handle signOut errors**

```dart
try { ... } catch (e) { ScaffoldMessenger.of(context).showSnackBar(...); }
```

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_account_menu_sheet.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart mobile/app/lib/app_providers.dart
git commit -m "feat(mobile): add web-like account menu with profile/logout actions"
```

### Task 4: Add Profile Route And Screen

**Files:**
- Modify: `mobile/app/lib/app_router.dart`
- Create: `mobile/app/lib/features/auth/ui/profile_screen.dart`

- [ ] **Step 1: Add route in router**

```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
),
```

- [ ] **Step 2: Build profile layout with fields/actions**

Include fields: `name`, `username`, `email`, `phone`, `dateOfBirth`, `bio`, avatar block, buttons `Отмена`/`Сохранить`.

- [ ] **Step 3: Reuse validators + phone mask/normalize**

```dart
inputFormatters: [PhoneRuMaskFormatter()]
phone: normalizePhoneRuToE164(_phone.text)
```

- [ ] **Step 4: Load initial values from current user + users/{uid}**

Use same hydration pattern as Google completion screen (`_hydrateFromFirestore`).

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze lib/app_router.dart lib/features/auth/ui/profile_screen.dart`

```bash
git add mobile/app/lib/app_router.dart mobile/app/lib/features/auth/ui/profile_screen.dart
git commit -m "feat(mobile): add profile page route and editable profile form"
```

### Task 5: Save Profile Changes End-to-End

**Files:**
- Modify: `mobile/app/lib/features/auth/ui/profile_screen.dart`
- Modify: `mobile/app/lib/app_providers.dart`

- [ ] **Step 1: Connect save action to existing service path**

Use `registrationServiceProvider`/existing profile update API (no schema change).

- [ ] **Step 2: Invalidate dependent providers after save**

```dart
ref.invalidate(authUserProvider);
ref.invalidate(registrationProfileStatusProvider(uid));
```

- [ ] **Step 3: Implement cancel reset behavior**

Store initial snapshot and restore controller values on `Отмена`.

- [ ] **Step 4: Show inline errors and success feedback**

Inline text for validation/server errors + snackbar on successful save.

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze lib/features/auth/ui/profile_screen.dart lib/app_providers.dart`

```bash
git add mobile/app/lib/features/auth/ui/profile_screen.dart mobile/app/lib/app_providers.dart
git commit -m "feat(mobile): implement profile save/cancel flow with provider refresh"
```

### Task 6: Docs Sync + Final Verification

**Files:**
- Modify: `docs/arcitecture/04-runtime-flows.md`
- Modify: `docs/arcitecture/01-codebase-map.md` (if new modules added)

- [ ] **Step 1: Update runtime flow doc**

Add mobile flow note for avatar menu and profile route `/profile`.

- [ ] **Step 2: Update codebase map doc**

Document new `chat_account_menu_sheet.dart` and `profile_screen.dart` responsibilities.

- [ ] **Step 3: Run full analyzer for mobile app**

Run: `flutter analyze`

- [ ] **Step 4: Manual verification checklist**

```text
1) Auth -> chats never blank; either chats or empty state
2) Bottom nav avatar opens menu
3) Profile row opens /profile
4) Logout row signs out and routes to /auth
5) Profile save updates values and keeps phone canonical format
```

- [ ] **Step 5: Commit docs/final touchups**

```bash
git add docs/arcitecture/04-runtime-flows.md docs/arcitecture/01-codebase-map.md
git commit -m "docs: sync mobile chat menu and profile flow architecture notes"
```
