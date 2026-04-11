# Mobile Google Auth Routing Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route Google-authenticated mobile users directly to `/chats` when required profile fields are complete, and to `/auth/google-complete` only when required fields are incomplete.

**Architecture:** Remove unconditional Google completion redirect from auth UI and replace it with runtime completeness decision using existing gate function. Align deep-link callback routing in `GoRouter.redirect` to the same decision, so direct Google flow and callback flow behave identically. Keep completeness criteria centralized in existing registration profile gate logic (`name`, `username`, `email`, `phone`).

**Tech Stack:** Flutter, Dart, Firebase Auth, GoRouter, flutter_test.

---

### Task 1: Add Routing Decision Helper for Google Flow

**Files:**
- Modify: `mobile/app/lib/features/auth/registration_profile_gate.dart`
- Test: `mobile/app/test/features/auth/registration_profile_gate_test.dart`

- [ ] **Step 1: Write the failing unit tests**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/auth/registration_profile_gate.dart';

void main() {
  test('googleRouteFromProfileComplete returns chats for complete profile', () {
    final route = googleRouteFromProfileComplete(true);
    expect(route, '/chats');
  });

  test('googleRouteFromProfileComplete returns completion for incomplete profile', () {
    final route = googleRouteFromProfileComplete(false);
    expect(route, '/auth/google-complete');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/registration_profile_gate_test.dart`
Expected: FAIL because `googleRouteFromProfileComplete` does not exist yet.

- [ ] **Step 3: Implement minimal helper**

```dart
String googleRouteFromProfileComplete(bool complete) {
  return complete ? '/chats' : '/auth/google-complete';
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/auth/registration_profile_gate_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/features/auth/registration_profile_gate.dart mobile/app/test/features/auth/registration_profile_gate_test.dart
git commit -m "feat(mobile): add shared Google auth route decision helper"
```

### Task 2: Fix Post-Google Sign-In Redirect in Auth Screen

**Files:**
- Modify: `mobile/app/lib/features/auth/ui/auth_screen.dart`
- Test: `mobile/app/test/features/auth/ui/auth_screen_google_redirect_test.dart`

- [ ] **Step 1: Write the failing widget-level decision test**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/auth/registration_profile_gate.dart';

void main() {
  test('complete profile maps to chats route', () {
    expect(googleRouteFromProfileComplete(true), '/chats');
  });

  test('incomplete profile maps to completion route', () {
    expect(googleRouteFromProfileComplete(false), '/auth/google-complete');
  });
}
```

- [ ] **Step 2: Run test to verify baseline behavior is not yet wired in UI**

Run: `flutter test test/features/auth/ui/auth_screen_google_redirect_test.dart`
Expected: PASS for helper mapping but manual code inspection still shows unconditional redirect in `auth_screen.dart`.

- [ ] **Step 3: Replace unconditional Google redirect with completeness decision**

Use this exact pattern in Google button handler:

```dart
await _run(() => repo.signInWithGoogle(), goChatsOnSuccess: false);
if (!context.mounted) return;

final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  context.go('/auth');
  return;
}

final complete = await isFirestoreRegistrationProfileCompleteWithDeadline(user);
if (!context.mounted) return;
context.go(googleRouteFromProfileComplete(complete));
```

Add imports:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../registration_profile_gate.dart';
```

- [ ] **Step 4: Run analyzer for changed files**

Run: `flutter analyze lib/features/auth/ui/auth_screen.dart lib/features/auth/registration_profile_gate.dart`
Expected: No new issues in changed files.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/features/auth/ui/auth_screen.dart
git commit -m "fix(mobile): route Google sign-in by profile completeness"
```

### Task 3: Fix Deep-Link Callback Redirect in Router

**Files:**
- Modify: `mobile/app/lib/app_router.dart`
- Modify: `mobile/app/lib/features/auth/registration_profile_gate.dart`
- Test: `mobile/app/test/app_router_google_callback_test.dart`

- [ ] **Step 1: Write failing callback mapping tests for pure helper**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:lighchat_mobile/features/auth/registration_profile_gate.dart';

void main() {
  test('callback route mapping for complete profile goes to chats', () {
    expect(googleRouteFromProfileComplete(true), '/chats');
  });

  test('callback route mapping for incomplete profile goes to completion', () {
    expect(googleRouteFromProfileComplete(false), '/auth/google-complete');
  });
}
```

- [ ] **Step 2: Run tests to verify helper behavior remains stable**

Run: `flutter test test/app_router_google_callback_test.dart`
Expected: PASS for helper mapping; router still needs integration.

- [ ] **Step 3: Wire callback redirect to completeness check**

Update `createRouter()` to async redirect and use this logic for callback:

```dart
if (uri.host == 'firebaseauth' && uri.path == '/link') {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return '/auth';
  final complete = await isFirestoreRegistrationProfileCompleteWithDeadline(user);
  return googleRouteFromProfileComplete(complete);
}
```

Add import:

```dart
import 'features/auth/registration_profile_gate.dart';
```

- [ ] **Step 4: Run analyzer and focused tests**

Run: `flutter test test/app_router_google_callback_test.dart && flutter analyze lib/app_router.dart lib/features/auth/registration_profile_gate.dart`
Expected: Tests PASS; analyzer clean for touched files.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/app_router.dart
git commit -m "fix(mobile): align Google callback routing with profile completeness"
```

### Task 4: End-to-End Validation for Required Fields Rule

**Files:**
- Verify behavior in: `mobile/app/lib/features/auth/registration_profile_gate.dart`
- Verify behavior in: `mobile/app/lib/features/auth/ui/auth_screen.dart`
- Verify behavior in: `mobile/app/lib/app_router.dart`

- [ ] **Step 1: Run complete static validation for app package**

Run: `flutter analyze`
Expected: No new issues introduced by this fix.

- [ ] **Step 2: Manual scenario A (complete profile)**

Run flow:

```text
1) Sign in with Google using account with valid name, username, email, phone in users/{uid}
2) Observe landing route
```

Expected: app lands on `/chats` with no intermediate completion form.

- [ ] **Step 3: Manual scenario B (incomplete profile)**

Run flow:

```text
1) Sign in with Google using account missing at least one required field
2) Observe landing route
```

Expected: app lands on `/auth/google-complete`.

- [ ] **Step 4: Manual scenario C (callback/deep-link)**

Run flow:

```text
1) Complete Google auth via platform callback (firebaseauth/link)
2) Validate routing outcome for complete/incomplete profile states
```

Expected: same route decisions as direct sign-in (complete -> `/chats`, incomplete -> `/auth/google-complete`).

- [ ] **Step 5: Commit only if validation artifacts are added**

```bash
git status
```

Expected: clean tree for planned files unless explicit test artifacts or docs were added.
