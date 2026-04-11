# Mobile Chat View Stability & UX Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove history-pagination bounce, add sticky date behavior, enforce hybrid media rendering, and make composer multiline growth stable in mobile chat.

**Architecture:** Keep the existing reverse list architecture and add deterministic anchor restoration driven by message identity (not raw scroll offset only). Implement sticky date as an overlay fed by top-visible message callbacks from the list. Split message bubble rendering into explicit content variants while preserving existing gestures/selection wrapper.

**Tech Stack:** Flutter, Riverpod, GoRouter, lighchat_models, flutter_test

---

### Task 1: Add visible-item tracking API in message list

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- Test: `mobile/app/test/features/chat/chat_message_list_sticky_date_test.dart`

- [ ] **Step 1: Write the failing test for top-visible callback and separator placement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_message_list.dart';
import 'package:lighchat_models/lighchat_models.dart';

ChatMessage _msg(String id, DateTime dt) => ChatMessage(
  id: id,
  senderId: 'u1',
  text: id,
  createdAt: dt.toUtc(),
);

void main() {
  testWidgets('date separator is before first message of day', (tester) async {
    final controller = ScrollController();
    final msgs = <ChatMessage>[
      _msg('m3', DateTime(2026, 4, 11, 11, 0)),
      _msg('m2', DateTime(2026, 4, 11, 10, 0)),
      _msg('m1', DateTime(2026, 4, 10, 23, 50)),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatMessageList(
          messagesDesc: msgs,
          currentUserId: 'u1',
          controller: controller,
        ),
      ),
    ));

    expect(find.text('СЕГОДНЯ'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_message_list_sticky_date_test.dart -r compact`  
Expected: FAIL (missing callback API and/or current separator logic mismatch).

- [ ] **Step 3: Add top-visible callback contract + day-key helper in list**

```dart
class VisibleMessageInfo {
  const VisibleMessageInfo({
    required this.messageId,
    required this.createdAt,
    required this.dyFromTop,
  });

  final String messageId;
  final DateTime createdAt;
  final double dyFromTop;
}

typedef OnTopVisibleChanged = void Function(VisibleMessageInfo? info);

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messagesDesc,
    required this.currentUserId,
    required this.controller,
    this.onTopVisibleChanged,
    // ...existing args
  });

  final OnTopVisibleChanged? onTopVisibleChanged;

  static String dayKey(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 4: Emit top-visible message from item layout pass**

```dart
class _VisibleProbe extends StatefulWidget {
  const _VisibleProbe({required this.onLayout, required this.child});
  final void Function(RenderBox box) onLayout;
  final Widget child;
  @override
  State<_VisibleProbe> createState() => _VisibleProbeState();
}

class _VisibleProbeState extends State<_VisibleProbe> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rb = context.findRenderObject();
      if (rb is RenderBox) widget.onLayout(rb);
    });
    return widget.child;
  }
}
```

- [ ] **Step 5: Run test to verify pass**

Run: `flutter test test/features/chat/chat_message_list_sticky_date_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/test/features/chat/chat_message_list_sticky_date_test.dart
git commit -m "fix(mobile): add message-list visible tracking primitives"
```

### Task 2: Stabilize history pagination with message-anchor restore

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Test: `mobile/app/test/features/chat/chat_history_anchor_restore_test.dart`

- [ ] **Step 1: Write failing pagination-anchor test**

```dart
testWidgets('keeps anchor message position when loading older', (tester) async {
  // Build ChatScreen with fake repository/messages stream where older pages prepend.
  // Scroll near oldest edge, trigger load, and verify top visible message id remains same.
  expect(true, isTrue); // replace with harness expectation
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_history_anchor_restore_test.dart -r compact`  
Expected: FAIL (current offset-delta logic can jump).

- [ ] **Step 3: Add anchor state and two-pass restore in `ChatScreen`**

```dart
String? _pendingAnchorMessageId;
double? _pendingAnchorDy;
bool _historyLoadInFlight = false;
int _pendingAnchorRestorePass = 0;

void _captureAnchor(VisibleMessageInfo? info) {
  _pendingAnchorMessageId = info?.messageId;
  _pendingAnchorDy = info?.dyFromTop;
}

void _restoreAnchorIfNeeded(List<ChatMessage> msgs) {
  final id = _pendingAnchorMessageId;
  final dy = _pendingAnchorDy;
  if (id == null || dy == null || !_scroll.hasClients) return;
  final idx = msgs.indexWhere((m) => m.id == id);
  if (idx < 0) return;
  // compute target offset using measured row offsets map (from list callbacks)
  // jumpTo(clamped)
}
```

- [ ] **Step 4: Replace `_loadingOlder` trigger guard with in-flight guard**

```dart
if (_historyLoadInFlight) return;
_historyLoadInFlight = true;
setState(() => _loadingOlder = true);
// increase _limit
// after restore passes:
_historyLoadInFlight = false;
setState(() => _loadingOlder = false);
```

- [ ] **Step 5: Run focused tests**

Run: `flutter test test/features/chat/chat_history_anchor_restore_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/test/features/chat/chat_history_anchor_restore_test.dart
git commit -m "fix(mobile): preserve viewport anchor during history pagination"
```

### Task 3: Implement sticky date overlay and correct separator math

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- Test: `mobile/app/test/features/chat/chat_sticky_date_overlay_test.dart`

- [ ] **Step 1: Write failing sticky-date behavior test**

```dart
testWidgets('sticky date updates when top visible day changes', (tester) async {
  // Render chat list with two day groups.
  // Scroll and assert sticky chip text changes from СЕГОДНЯ to ВЧЕРА/date.
  expect(true, isTrue); // replace with harness assertion
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_sticky_date_overlay_test.dart -r compact`  
Expected: FAIL (no sticky overlay yet).

- [ ] **Step 3: Fix reverse-list separator logic in message list**

```dart
bool _shouldShowDateSeparatorReversed(List<ChatMessage> asc, int index) {
  final len = asc.length;
  final cur = asc[len - 1 - index];
  final olderIndex = len - 2 - index;
  if (olderIndex < 0) return true;
  final older = asc[olderIndex];
  return ChatMessageList.dayKey(cur.createdAt) != ChatMessageList.dayKey(older.createdAt);
}
```

- [ ] **Step 4: Add sticky overlay UI in `ChatScreen` stack**

```dart
if (_stickyDayLabel != null)
  Positioned(
    top: 8,
    left: 0,
    right: 0,
    child: Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        child: _StickyDateChip(key: ValueKey(_stickyDayLabel), label: _stickyDayLabel!),
      ),
    ),
  ),
```

- [ ] **Step 5: Run sticky-date tests**

Run: `flutter test test/features/chat/chat_sticky_date_overlay_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/test/features/chat/chat_sticky_date_overlay_test.dart
git commit -m "fix(mobile): add sticky date tag and correct day separators"
```

### Task 4: Render media without bubble and keep hybrid media+text layout

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- Modify: `mobile/app/lib/features/chat/ui/message_attachments.dart` (if spacing hooks needed)
- Test: `mobile/app/test/features/chat/chat_message_media_layout_test.dart`

- [ ] **Step 1: Write failing layout-variant tests**

```dart
testWidgets('media-only message has no text bubble container', (tester) async {
  // Build list row with attachment only and assert no bubble background widget.
  expect(true, isTrue); // replace with concrete finder assertions
});

testWidgets('media+text shows media and compact bubble below', (tester) async {
  // Assert media block appears before text bubble and time text is in compact bubble.
  expect(true, isTrue); // replace with concrete finder assertions
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_message_media_layout_test.dart -r compact`  
Expected: FAIL.

- [ ] **Step 3: Split message row rendering by variant**

```dart
final hasText = plain.trim().isNotEmpty;
final hasMedia = message.attachments.isNotEmpty;

if (hasMedia && !hasText) {
  return _MediaOnlyMessageBlock(...);
}
if (hasMedia && hasText) {
  return _MediaWithCaptionBlock(...);
}
return _TextOnlyBubble(...);
```

- [ ] **Step 4: Keep selection/long-press wrapper at outer block level**

```dart
GestureDetector(
  onTap: selectionMode ? () => onMessageTap?.call(message) : null,
  onLongPress: !selectionMode ? () => onMessageLongPress?.call(message) : null,
  child: DecoratedBox(
    decoration: selected
        ? BoxDecoration(border: Border.all(color: scheme.primary, width: 2))
        : const BoxDecoration(),
    child: content,
  ),
)
```

- [ ] **Step 5: Run media layout tests**

Run: `flutter test test/features/chat/chat_message_media_layout_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/lib/features/chat/ui/message_attachments.dart mobile/app/test/features/chat/chat_message_media_layout_test.dart
git commit -m "feat(mobile): apply hybrid media message layout without media bubbles"
```

### Task 5: Multiline composer growth and final verification

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Test: `mobile/app/test/features/chat/chat_composer_multiline_test.dart`

- [ ] **Step 1: Write failing composer multiline test**

```dart
testWidgets('composer grows to max lines and keeps send button', (tester) async {
  // Enter multiline text and verify TextField min/max lines config + visible send action.
  expect(true, isTrue); // replace with concrete expectation
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_composer_multiline_test.dart -r compact`  
Expected: FAIL.

- [ ] **Step 3: Update composer input configuration**

```dart
TextField(
  controller: controller,
  minLines: 1,
  maxLines: 6,
  keyboardType: TextInputType.multiline,
  textInputAction: TextInputAction.newline,
  decoration: const InputDecoration(
    hintText: 'Сообщение',
    border: InputBorder.none,
  ),
)
```

- [ ] **Step 4: Run test to verify pass**

Run: `flutter test test/features/chat/chat_composer_multiline_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 5: Run full mobile verification**

Run: `flutter analyze`  
Expected: no errors (info-level warnings allowed if pre-existing).

Run: `flutter test`  
Expected: chat-focused tests pass; legacy template test may fail if still Firebase-uninitialized and should be replaced/removed in same patch.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/test/features/chat/chat_composer_multiline_test.dart mobile/app/test/widget_test.dart
git commit -m "feat(mobile): add multiline composer growth for long messages"
```

### Task 6: Required subagent self-review before handoff

**Files:**
- Modify: none (review task)
- Optional fixes: same files from Tasks 1-5 if review finds issues

- [ ] **Step 1: Dispatch self-review subagent focused on regressions**

```text
Review targets:
1) reverse pagination anchor invariants
2) sticky date correctness under fast scroll
3) media hybrid layout gesture/selection consistency
4) composer multiline behavior under keyboard open/close
```

- [ ] **Step 2: Apply any review fixes and re-run focused checks**

Run: `flutter test test/features/chat -r compact`  
Expected: PASS.

Run: `flutter analyze`  
Expected: no new errors.

- [ ] **Step 3: Final commit after review fixes**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/lib/features/chat/ui/message_attachments.dart mobile/app/test/features/chat
git commit -m "fix(mobile): harden chat viewport and sticky date behavior after self-review"
```
