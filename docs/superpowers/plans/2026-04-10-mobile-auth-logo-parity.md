# Mobile Auth Logo Parity With Web Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Flutter auth screens use the same branding composition as web auth (shared mark + two-tone `LighChat` text) instead of a single baked wordmark image.

**Architecture:** Introduce a reusable `AuthBrandHeader` widget in the mobile auth UI layer, then replace duplicate top logo blocks in both auth screens with that shared component. Keep auth logic untouched and validate with analyzer plus targeted widget tests.

**Tech Stack:** Flutter, Dart, flutter_test, existing mobile auth UI components.

---

### Task 1: Build Shared Auth Brand Header Component

**Files:**
- Create: `mobile/app/lib/features/auth/ui/auth_brand_header.dart`
- Test: `mobile/app/test/features/auth/ui/auth_brand_header_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/auth/ui/auth_brand_header.dart';

void main() {
  testWidgets('AuthBrandHeader renders mark asset and two-tone title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthBrandHeader(),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;
    expect(provider, isA<AssetImage>());
    expect((provider as AssetImage).assetName, 'assets/lighchat_mark.png');

    expect(find.text('Ligh'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/ui/auth_brand_header_test.dart`
Expected: FAIL with import/file-not-found for `auth_brand_header.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const navy = Color(0xFF1E3A5F);
    const coral = Color(0xFFE9967A);
    final lighColor = isDark ? const Color(0xFFC5D9ED) : navy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140, maxHeight: 140),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(
              'assets/lighchat_mark.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.4,
            ),
            children: [
              TextSpan(text: 'Ligh', style: TextStyle(color: lighColor)),
              const TextSpan(text: 'Chat', style: TextStyle(color: coral)),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/auth/ui/auth_brand_header_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/features/auth/ui/auth_brand_header.dart mobile/app/test/features/auth/ui/auth_brand_header_test.dart
git commit -m "feat(mobile): add shared auth brand header"
```

### Task 2: Replace Logo Block in Sign-In Screen

**Files:**
- Modify: `mobile/app/lib/features/auth/ui/auth_screen.dart`
- Test: `mobile/app/test/features/auth/ui/auth_screen_brand_header_test.dart`

- [ ] **Step 1: Write the failing screen integration test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/auth/ui/auth_brand_header.dart';
import 'package:lighchat_mobile/features/auth/ui/auth_screen.dart';

void main() {
  testWidgets('AuthScreen uses AuthBrandHeader', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    expect(find.byType(AuthBrandHeader), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/ui/auth_screen_brand_header_test.dart`
Expected: FAIL because `AuthBrandHeader` is not yet mounted in `AuthScreen`.

- [ ] **Step 3: Replace old image block with shared header**

```dart
import 'auth_brand_header.dart';

// inside Column children
const Center(child: AuthBrandHeader()),
const SizedBox(height: 12),
```

Also remove old block:

```dart
Center(
  child: Image.asset(
    'assets/lighchat_wordmark.png',
    height: 120,
    fit: BoxFit.contain,
  ),
),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/auth/ui/auth_screen_brand_header_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/features/auth/ui/auth_screen.dart mobile/app/test/features/auth/ui/auth_screen_brand_header_test.dart
git commit -m "refactor(mobile): reuse auth brand header on sign-in"
```

### Task 3: Replace Logo Block in Google Completion Screen + Full Validation

**Files:**
- Modify: `mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart`
- Test: `mobile/app/test/features/auth/ui/google_complete_profile_brand_header_test.dart`

- [ ] **Step 1: Write the failing screen integration test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/auth/ui/auth_brand_header.dart';
import 'package:lighchat_mobile/features/auth/ui/google_complete_profile_screen.dart';

void main() {
  testWidgets('GoogleCompleteProfileScreen uses AuthBrandHeader', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GoogleCompleteProfileScreen()));
    expect(find.byType(AuthBrandHeader), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/ui/google_complete_profile_brand_header_test.dart`
Expected: FAIL because current screen still renders `assets/lighchat_wordmark.png`.

- [ ] **Step 3: Replace old image block and keep flow intact**

```dart
import 'auth_brand_header.dart';

// inside content column
const Center(child: AuthBrandHeader()),
const SizedBox(height: 12),
```

Remove old asset usage:

```dart
Center(
  child: Image.asset(
    'assets/lighchat_wordmark.png',
    height: 96,
    fit: BoxFit.contain,
  ),
),
```

- [ ] **Step 4: Run tests and analyzer for end-to-end validation**

Run: `flutter test test/features/auth/ui/google_complete_profile_brand_header_test.dart && flutter analyze`
Expected: Tests PASS, analyzer returns no new issues in touched files.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart mobile/app/test/features/auth/ui/google_complete_profile_brand_header_test.dart
git commit -m "refactor(mobile): align google completion branding with web auth"
```

### Task 4: Final Visual QA Checklist

**Files:**
- Verify only: `mobile/app/lib/features/auth/ui/auth_screen.dart`
- Verify only: `mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart`

- [ ] **Step 1: Launch app and open auth routes**

Run: `flutter run`
Expected: App boots and auth screens open without runtime exceptions.

- [ ] **Step 2: Verify visual parity requirements manually**

Check:

```text
1) Mark uses assets/lighchat_mark.png
2) Wordmark is two-tone text: Ligh (#1E3A5F or dark-theme fallback), Chat (#E9967A)
3) Header is centered and does not clip on compact screens
4) Sign-in and Google completion screens show the same header
```

- [ ] **Step 3: Final commit for QA note (optional if no file changes)**

```bash
git status
```

Expected: clean working tree for planned files.
