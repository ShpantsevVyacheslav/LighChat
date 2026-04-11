# Mobile Google Auth Routing Parity Design

## Context

In Flutter mobile auth, users who sign in with Google can be redirected to `/auth/google-complete` even when their profile is already complete. This creates a mismatch with expected behavior and web parity.

Expected behavior:

- If required profile fields are complete, route directly to `/chats`.
- If required profile fields are incomplete, route to `/auth/google-complete`.

## Required Profile Completeness Rules

Profile is considered complete only when all required fields are valid:

- `name`
- `username`
- `email`
- `phone`

Non-required fields must not influence routing:

- `dateOfBirth`
- `bio`
- avatar and other optional fields

The existing `isRegistrationProfileComplete(...)` criteria remain the single source of truth.

## Scope

In scope:

- Fix post-Google sign-in routing in mobile auth screen.
- Fix deep-link callback routing in mobile router for `firebaseauth/link`.
- Keep profile completeness logic centralized and unchanged in semantics.

Out of scope:

- Refactoring broader auth architecture.
- Changing registration validation rules.
- Modifying backend/Firestore schema.

## Selected Approach

Use dynamic route selection immediately after Google sign-in and in router callback handling, based on existing profile completeness check.

Why this approach:

- Removes false redirect to completion screen for fully completed profiles.
- Preserves safe behavior for incomplete profiles.
- Minimal, targeted change with low regression risk.

## Design

### 1) Post-Google sign-in flow (`auth_screen.dart`)

Current issue: after `signInWithGoogle()` mobile flow unconditionally navigates to `/auth/google-complete`.

New behavior:

1. Sign in with Google.
2. Read `FirebaseAuth.instance.currentUser`.
3. Run `isFirestoreRegistrationProfileCompleteWithDeadline(currentUser)`.
4. Route based on result:
   - complete -> `/chats`
   - incomplete/unknown -> `/auth/google-complete`

Unknown (timeout/read failure) intentionally falls back to completion screen as safe default.

### 2) Deep-link callback routing (`app_router.dart`)

Current issue: `firebaseauth/link` callback is force-mapped to `/auth/google-complete`.

New behavior:

- For callback URI (`host == firebaseauth`, `path == /link`), evaluate current user completeness with the same check.
- Redirect to `/chats` when complete.
- Redirect to `/auth/google-complete` otherwise.

This ensures callback route uses the same decision model as direct sign-in completion.

### 3) Consistency and shared criteria

- Do not introduce a second completeness function.
- Reuse existing gate logic already aligned with required fields (`name`, `username`, `email`, `phone`).

## Error Handling

- If current user is null right after callback/sign-in processing, use existing auth flow behavior (stay in auth path until user is available).
- If profile check throws or times out, route to `/auth/google-complete` and emit diagnostic logs.
- No crash path added to UI.

## Testing Strategy

1. Static validation
   - `flutter analyze` for changed files.

2. Behavioral manual scenarios
   - Scenario A: Google user with complete required profile fields -> lands on `/chats`.
   - Scenario B: Google user missing required fields -> lands on `/auth/google-complete`.
   - Scenario C: iOS/Android callback via `firebaseauth/link` -> same routing outcome by profile state.

3. Regression checks
   - Email/password sign-in path unchanged.
   - Existing completion screen submit path unchanged.

## Acceptance Criteria

- No unconditional redirect to `/auth/google-complete` after Google sign-in.
- Routing decision is based on required profile fields only (`name`, `username`, `email`, `phone`).
- Complete Google accounts enter app (`/chats`) directly.
- Incomplete Google accounts are routed to `/auth/google-complete`.
- Callback-based Google auth follows the same decision path.
