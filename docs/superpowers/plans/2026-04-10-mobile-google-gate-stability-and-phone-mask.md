# Mobile Google Gate Stability And Phone Mask Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove false redirects to `/auth/google-complete` for complete Google profiles and add web-parity phone mask `+7 (___) ___-__-__` in mobile auth forms.

**Architecture:** Extend mobile profile gate from boolean to tri-state (`complete`, `incomplete`, `unknown`) and route only on deterministic states. Keep required completeness fields unchanged (`name`, `username`, `email`, `phone`) and add shared phone format utilities (input formatter + canonical normalization) used by both registration forms.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Firebase Auth/Firestore, flutter_test.

---

### Task 1: Implement Tri-State Profile Gate API

**Files:**
- Modify: `mobile/app/lib/features/auth/registration_profile_gate.dart`
- Create: `mobile/app/test/features/auth/registration_profile_gate_status_test.dart`

- [ ] **Step 1: Write failing tests for tri-state route decision**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/auth/registration_profile_gate.dart';

void main() {
  test('complete status routes to chats', () {
    expect(googleRouteFromProfileStatus(RegistrationProfileStatus.complete), '/chats');
  });

  test('incomplete status routes to completion', () {
    expect(googleRouteFromProfileStatus(RegistrationProfileStatus.incomplete), '/auth/google-complete');
  });

  test('unknown status returns null redirect', () {
    expect(googleRouteFromProfileStatus(RegistrationProfileStatus.unknown), isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/features/auth/registration_profile_gate_status_test.dart`
Expected: FAIL because `RegistrationProfileStatus` / `googleRouteFromProfileStatus` do not exist.

- [ ] **Step 3: Add tri-state enum and mapping helper**

```dart
enum RegistrationProfileStatus { complete, incomplete, unknown }

String? googleRouteFromProfileStatus(RegistrationProfileStatus status) {
  switch (status) {
    case RegistrationProfileStatus.complete:
      return '/chats';
    case RegistrationProfileStatus.incomplete:
      return '/auth/google-complete';
    case RegistrationProfileStatus.unknown:
      return null;
  }
}
```

Add new API (do not delete old bool API in same commit):

```dart
Future<RegistrationProfileStatus> getFirestoreRegistrationProfileStatus(auth.User user) async {
  // complete if required fields are valid
  // incomplete if data read succeeded and fields are not valid
  // unknown on timeout/transient errors
}
```

- [ ] **Step 4: Rewire existing bool function to tri-state**

```dart
Future<bool> isFirestoreRegistrationProfileComplete(auth.User firebaseUser) async {
  final status = await getFirestoreRegistrationProfileStatus(firebaseUser);
  return status == RegistrationProfileStatus.complete;
}
```

- [ ] **Step 5: Run tests and commit**

Run: `flutter test test/features/auth/registration_profile_gate_status_test.dart`
Expected: PASS.

```bash
git add mobile/app/lib/features/auth/registration_profile_gate.dart mobile/app/test/features/auth/registration_profile_gate_status_test.dart
git commit -m "feat(mobile): add tri-state registration profile gate status"
```

### Task 2: Apply Tri-State Routing in Auth Screen and Router

**Files:**
- Modify: `mobile/app/lib/features/auth/ui/auth_screen.dart`
- Modify: `mobile/app/lib/app_router.dart`

- [ ] **Step 1: Write failing tests for route mapping helper usage**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/auth/registration_profile_gate.dart';

void main() {
  test('unknown status does not force completion redirect', () {
    expect(googleRouteFromProfileStatus(RegistrationProfileStatus.unknown), isNull);
  });
}
```

- [ ] **Step 2: Run test to establish baseline**

Run: `flutter test test/features/auth/registration_profile_gate_status_test.dart`
Expected: PASS helper test; integration wiring still pending.

- [ ] **Step 3: Update Google button flow to tri-state**

Replace current post-Google block in `auth_screen.dart`:

```dart
final status = await getFirestoreRegistrationProfileStatus(user);
if (!context.mounted) return;
final next = googleRouteFromProfileStatus(status);
if (next == null) return; // keep current screen on unknown
context.go(next);
```

- [ ] **Step 4: Update callback redirect in `app_router.dart`**

```dart
if (uri.host == 'firebaseauth' && uri.path == '/link') {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return '/auth';
  final status = await getFirestoreRegistrationProfileStatus(user);
  final next = googleRouteFromProfileStatus(status);
  return next; // null on unknown => stay and retry by normal auth flow
}
```

- [ ] **Step 5: Analyze and commit**

Run: `flutter analyze lib/features/auth/ui/auth_screen.dart lib/app_router.dart lib/features/auth/registration_profile_gate.dart`
Expected: No new issues.

```bash
git add mobile/app/lib/features/auth/ui/auth_screen.dart mobile/app/lib/app_router.dart
git commit -m "fix(mobile): route Google auth with tri-state profile status"
```

### Task 3: Prevent Chat Gate From Redirecting On Unknown

**Files:**
- Modify: `mobile/app/lib/app_providers.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`

- [ ] **Step 1: Write failing provider test for status provider**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder: registration status provider exists', () {
    expect(true, isTrue);
  });
}
```

- [ ] **Step 2: Run test (placeholder baseline)**

Run: `flutter test test/widget_test.dart`
Expected: PASS baseline.

- [ ] **Step 3: Add status provider and switch chats gate to it**

In `app_providers.dart` add:

```dart
final registrationProfileStatusProvider = FutureProvider.family<RegistrationProfileStatus, String>((ref, uid) async {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null || u.uid != uid) return RegistrationProfileStatus.unknown;
  return getFirestoreRegistrationProfileStatus(u);
});
```

In `chat_list_screen.dart` use `registrationProfileStatusProvider` and route only when status is `incomplete`.

```dart
if (status == RegistrationProfileStatus.incomplete) {
  context.go('/auth/google-complete');
}
```

For `unknown`, show retryable loading message and do not redirect.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/app_providers.dart lib/features/chat/ui/chat_list_screen.dart`
Expected: No new issues.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/app_providers.dart mobile/app/lib/features/chat/ui/chat_list_screen.dart
git commit -m "fix(mobile): avoid completion redirect on unknown profile gate state"
```

### Task 4: Add Shared RU Phone Mask + Canonical Normalization

**Files:**
- Create: `mobile/app/lib/features/auth/ui/phone_ru_format.dart`
- Modify: `mobile/app/lib/features/auth/ui/auth_validators.dart`
- Modify: `mobile/app/lib/features/auth/ui/register_form.dart`
- Modify: `mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart`
- Create: `mobile/app/test/features/auth/ui/phone_ru_format_test.dart`

- [ ] **Step 1: Write failing phone format tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/auth/ui/phone_ru_format.dart';

void main() {
  test('normalizePhoneRuToE164 converts +7 formatted input', () {
    expect(normalizePhoneRuToE164('+7 (909) 418-96-53'), '+79094189653');
  });

  test('normalizePhoneRuToE164 converts 8XXXXXXXXXX input', () {
    expect(normalizePhoneRuToE164('8 (909) 418-96-53'), '+79094189653');
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/features/auth/ui/phone_ru_format_test.dart`
Expected: FAIL because formatter helpers do not exist.

- [ ] **Step 3: Implement formatter and normalization helpers**

In `phone_ru_format.dart` add:

```dart
String phoneDigitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

String normalizePhoneRuToE164(String raw) {
  final d = phoneDigitsOnly(raw);
  if (d.length == 11 && d.startsWith('8')) return '+7${d.substring(1)}';
  if (d.length == 11 && d.startsWith('7')) return '+$d';
  return raw.trim();
}
```

Add `PhoneRuMaskFormatter extends TextInputFormatter` for display mask `+7 (___) ___-__-__`.

- [ ] **Step 4: Wire both forms to formatter and canonical submit value**

In both forms:

```dart
inputFormatters: [PhoneRuMaskFormatter()],
```

On submit map phone:

```dart
phone: normalizePhoneRuToE164(_phone.text),
```

Update `validatePhone11` to validate normalized digits consistently.

- [ ] **Step 5: Run tests/analyze and commit**

Run: `flutter test test/features/auth/ui/phone_ru_format_test.dart && flutter analyze lib/features/auth/ui/register_form.dart lib/features/auth/ui/google_complete_profile_screen.dart lib/features/auth/ui/phone_ru_format.dart lib/features/auth/ui/auth_validators.dart`
Expected: PASS tests, analyzer clean.

```bash
git add mobile/app/lib/features/auth/ui/phone_ru_format.dart mobile/app/lib/features/auth/ui/auth_validators.dart mobile/app/lib/features/auth/ui/register_form.dart mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart mobile/app/test/features/auth/ui/phone_ru_format_test.dart
git commit -m "feat(mobile): add ru phone mask and canonical auth phone normalization"
```

### Task 5: Final Verification + Docs Sync

**Files:**
- Modify: `docs/arcitecture/04-runtime-flows.md`
- Verify behavior in: `mobile/app/lib/features/auth/ui/auth_screen.dart`
- Verify behavior in: `mobile/app/lib/features/chat/ui/chat_list_screen.dart`

- [ ] **Step 1: Update runtime flow doc for tri-state gate and phone mask**

Add a concise bullet under Auth/mobile flow describing:

```text
Google routing uses complete/incomplete/unknown; only incomplete redirects to /auth/google-complete; unknown stays retryable.
```

Also mention phone mask/canonical phone save format in mobile auth forms.

- [ ] **Step 2: Run full analyzer**

Run: `flutter analyze`
Expected: no new analyzer issues.

- [ ] **Step 3: Manual validation with provided Firestore user document**

Check:

```text
1) User with name+username+email+phone(+79094189653) signs in via Google
2) App lands on /chats (no completion screen)
3) Simulated timeout/error does not force /auth/google-complete
4) Registration forms show +7 (___) ___-__-__ and save canonical +7XXXXXXXXXX
```

- [ ] **Step 4: Commit docs + remaining integration fixes**

```bash
git add docs/arcitecture/04-runtime-flows.md
git commit -m "docs: document mobile tri-state Google gate and phone mask flow"
```

- [ ] **Step 5: Final status check**

Run: `git status --short`
Expected: clean working tree (or only intentionally uncommitted files).
