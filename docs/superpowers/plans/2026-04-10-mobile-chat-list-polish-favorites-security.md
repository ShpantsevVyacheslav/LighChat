# Mobile Chat List Polish + Favorites Security Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver compact chat-list UI polish, favorites shortcut parity, saved-chat privacy hardening, avatar fallback fixes, and stable history scroll anchoring.

**Architecture:** Implement targeted UI adjustments in chat list/menu/settings screens, add favorites pseudo-folder logic in the chat list coordinator, and tighten Firestore read rules for saved-messages conversations in both rule files. Keep behavior deterministic by preserving existing provider flows and adding isolated helper logic for favorites resolution and scroll anchoring.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Firebase Firestore rules, LighChat mobile packages.

---

### Task 1: Compact chat-list top area and search/input spacing

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_folder_bar.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_bottom_nav.dart`

- [ ] **Step 1: Write failing UI expectations in temporary smoke test**

```dart
testWidgets('chat list top area has compact spacing', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: ChatListScreen()));
  expect(find.text('Чаты'), findsNothing);
});
```

- [ ] **Step 2: Run test to verify current mismatch**

Run: `flutter test test/widget_test.dart`
Expected: FAIL or no explicit coverage for compact spacing.

- [ ] **Step 3: Tighten spacing and reduce search input height**

Apply concrete changes:

```dart
// chat_list_screen.dart
const SizedBox(height: 4); // previously larger

// chat_folder_bar.dart search field
constraints: const BoxConstraints(minHeight: 56), // reduced
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
```

- [ ] **Step 4: Reduce bottom-nav bottom air**

```dart
// chat_bottom_nav.dart
padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // reduce bottom padding
```

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_list_screen.dart lib/features/chat/ui/chat_folder_bar.dart lib/features/chat/ui/chat_bottom_nav.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_list_screen.dart mobile/app/lib/features/chat/ui/chat_folder_bar.dart mobile/app/lib/features/chat/ui/chat_bottom_nav.dart
git commit -m "style(mobile): compact chat list top/search/nav spacing"
```

### Task 2: Tune account menu opacity and readability

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart`

- [ ] **Step 1: Apply stronger surface opacity and contrast**

```dart
color: (dark ? const Color(0xFF0E1A22) : Colors.white).withValues(alpha: dark ? 0.95 : 0.97)
```

And row cards similarly less transparent.

- [ ] **Step 2: Ensure text contrast remains accessible**

Keep icon/text alpha >= previous levels for non-warning rows.

- [ ] **Step 3: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_account_menu_sheet.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart
git commit -m "style(mobile): reduce profile menu transparency"
```

### Task 3: Remove `Нижнее меню` section from chat settings

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_settings_screen.dart`

- [ ] **Step 1: Remove section UI and related handlers**

Delete only this block:

```dart
Text('Нижнее меню')
// colorful/minimal cards
```

- [ ] **Step 2: Keep persisted field intact**

Do not alter existing `chatSettings.bottomNavAppearance` data in DB.

- [ ] **Step 3: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_settings_screen.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_settings_screen.dart
git commit -m "refactor(mobile): remove bottom-nav section from chat settings screen"
```

### Task 4: Add Favorites pseudo-folder with auto-create + open

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`
- Modify: `mobile/app/lib/features/chat/data/saved_messages_chat.dart`
- Modify: `mobile/app/lib/app_providers.dart` (if helper provider needed)
- Modify: `mobile/packages/lighchat_firebase/lib/src/chat_repository.dart` (if creation helper missing)

- [ ] **Step 1: Add `Избранное` chip before other folders**

```dart
final favorites = ChatFolder(id: 'favorites', name: 'Избранное', conversationIds: const []);
return <ChatFolder>[favorites, all, unread, personal, groups, ...custom];
```

- [ ] **Step 2: Intercept favorites tap to open saved chat, not filter list**

```dart
if (id == 'favorites') {
  await _openSavedMessagesChat();
  return;
}
```

- [ ] **Step 3: Implement resolve/create saved chat helper**

Pseudo:

```dart
Future<String> ensureSavedChatId(String uid) async {
  final existing = conversations.firstWhereOrNull((c) => isSavedMessagesConversation(c.data, uid));
  if (existing != null) return existing.id;
  return await repo.ensureSavedMessagesChat(userId: uid);
}
```

- [ ] **Step 4: Navigate directly to chat**

```dart
context.go('/chats/$savedChatId');
```

- [ ] **Step 5: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_list_screen.dart lib/features/chat/data/saved_messages_chat.dart mobile/packages/lighchat_firebase/lib/src/chat_repository.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_list_screen.dart mobile/app/lib/features/chat/data/saved_messages_chat.dart mobile/packages/lighchat_firebase/lib/src/chat_repository.dart
git commit -m "feat(mobile): add favorites pseudo-folder with auto-create saved chat"
```

### Task 5: Harden Firestore rules for saved-chat privacy

**Files:**
- Modify: `firestore.rules`
- Modify: `src/firestore.rules`

- [ ] **Step 1: Add helper for saved-chat detection**

```rules
function isSavedMessagesConversationData(data) {
  return data.participantIds is list && data.participantIds.size() == 1;
}
```

- [ ] **Step 2: Restrict saved-chat reads to owner only**

In `match /conversations/{conversationId}` read condition, enforce:

```rules
allow read: if isSignedIn() && (
  isAdmin() ||
  (
    (resource != null && isSavedMessagesConversationData(resource.data))
      ? uidIsConversationParticipantFromData(resource.data)
      : (
          exists(/databases/$(database)/documents/conversations/$(conversationId)/members/$(request.auth.uid)) ||
          (resource != null && uidIsConversationParticipantFromData(resource.data))
        )
  )
);
```

- [ ] **Step 3: Keep rule files synchronized**

Mirror exact logic in `src/firestore.rules`.

- [ ] **Step 4: Validate rule consistency**

Run visual diff or compare blocks manually.

- [ ] **Step 5: Commit**

```bash
git add firestore.rules src/firestore.rules
git commit -m "fix(rules): block cross-user reads of saved messages conversations"
```

### Task 6: Improve avatar fallback for auto-assigned chats

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_list_item.dart`

- [ ] **Step 1: Add participantInfo fallback in list mapping**

```dart
avatarUrl = p?.avatarThumb ?? p?.avatar ?? c.data.participantInfo?[other]?.avatarThumb ?? c.data.participantInfo?[other]?.avatar;
```

- [ ] **Step 2: Keep robust placeholder behavior in item widget**

Ensure `_AvatarCircle` always falls back to initials if URL empty/invalid.

- [ ] **Step 3: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_list_screen.dart lib/features/chat/ui/chat_list_item.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_list_screen.dart mobile/app/lib/features/chat/ui/chat_list_item.dart
git commit -m "fix(mobile): improve chat avatar fallback for auto-assigned chats"
```

### Task 7: Fix history scroll bounce-to-bottom during older paging

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`

- [ ] **Step 1: Capture scroll anchor before increasing limit**

```dart
final prevPixels = pos.pixels;
final prevMax = pos.maxScrollExtent;
```

- [ ] **Step 2: Restore anchor after frame when list grows**

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final newMax = _scroll.position.maxScrollExtent;
  final anchor = prevPixels + (newMax - prevMax);
  _scroll.jumpTo(anchor.clamp(_scroll.position.minScrollExtent, _scroll.position.maxScrollExtent));
});
```

- [ ] **Step 3: Keep send-to-bottom behavior only on explicit send**

Do not modify `_send` auto-scroll path.

- [ ] **Step 4: Analyze + commit**

Run: `flutter analyze lib/features/chat/ui/chat_screen.dart`

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart
git commit -m "fix(mobile): preserve scroll anchor when loading older chat history"
```

### Task 8: Docs sync and verification

**Files:**
- Modify: `docs/arcitecture/04-runtime-flows.md`
- Modify: `docs/arcitecture/03-firestore-model.md`
- Modify: `docs/arcitecture/01-codebase-map.md` (if structural notes changed)

- [ ] **Step 1: Update runtime flow docs**

Document favorites pseudo-folder open/create behavior and compacted chat-list UI.

- [ ] **Step 2: Update firestore model/security docs**

Describe saved-chat read restriction in rules.

- [ ] **Step 3: Run analyzer for touched mobile files**

Run: `flutter analyze`

- [ ] **Step 4: Manual checklist**

```text
1) Top chat-list area is tighter, search row lower height
2) Bottom nav sits closer to screen bottom
3) Profile menu less transparent
4) Chat settings has no 'Нижнее меню' section
5) Favorites chip opens/creates saved chat directly
6) Other users' favorites are not visible/readable
7) Auto-assigned avatars appear correctly
8) Loading older messages no longer bounces to latest
```

- [ ] **Step 5: Commit docs/final adjustments**

```bash
git add docs/arcitecture/04-runtime-flows.md docs/arcitecture/03-firestore-model.md docs/arcitecture/01-codebase-map.md
git commit -m "docs: sync favorites shortcut, chat list polish, and saved-chat security behavior"
```
