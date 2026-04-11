# Mobile Google Gate Stability And Phone Mask Design

## Context

Google sign-in on Flutter mobile can incorrectly route a user with a complete profile to `/auth/google-complete`.

Observed user document in Firestore contains valid required fields (`name`, `username`, `email`, `phone`), including `phone = "+79094189653"`, which should be considered complete by existing validation rules.

This indicates routing false-negatives are caused by gate/read timing or error handling, not by profile data shape.

## Goals

- Stop false redirects to `/auth/google-complete` for already complete Google profiles.
- Keep required-field completeness rules unchanged.
- Add mobile phone input mask parity with web (`+7 (___) ___-__-__`).

## Required Completeness Criteria

Profile is complete when all required fields are valid:

- `name`
- `username`
- `email`
- `phone`

Optional fields (`dateOfBirth`, `bio`, avatar, preferences) must not affect route decision.

## Scope

In scope:

- Stabilize mobile Google routing decision when profile check cannot be resolved immediately.
- Add phone mask UX in mobile auth forms.
- Normalize phone value before save for consistency.

Out of scope:

- Schema migration of all existing users.
- Broad auth architecture rewrite.
- Backend-only profile-complete source replacement.

## Selected Approach

### 1) Introduce tri-state profile gate result

Replace binary gate outcome (`complete`/`incomplete`) with tri-state in mobile flow:

- `complete`
- `incomplete`
- `unknown` (timeout, transient permission/auth/cache error)

Routing behavior:

- `complete` -> `/chats`
- `incomplete` -> `/auth/google-complete`
- `unknown` -> do not force completion redirect; keep loading/retry path and re-check

This prevents treating transient read failures as true profile incompleteness.

### 2) Keep deterministic completeness by required fields

Do not make `profileComplete` field in Firestore the primary source of truth.

Reason: stored flags can become stale and diverge from real field values.

Optional future optimization: add server-maintained cache flag (`profileComplete`) for diagnostics/perf only, but always preserve deterministic fallback from fields.

### 3) Add phone mask parity in mobile forms

Apply `+7 (___) ___-__-__` input masking in:

- `mobile/app/lib/features/auth/ui/register_form.dart`
- `mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart`

On submit, normalize to canonical stored value `+7XXXXXXXXXX`.

Current valid values like `+79094189653` remain valid and should pass completeness checks.

## Runtime Flow Changes

Mobile routing decisions (Google sign-in button path, `firebaseauth/link` callback path, and chats gate path) must consistently use tri-state semantics so that unknown state never hard-redirects to completion form.

## Error Handling

- Log explicit reason codes for non-complete decisions:
  - `missing_required_field`
  - `firestore_timeout`
  - `permission_denied_retry_failed`
  - `unknown_auth_state`
- Unknown state should surface retryable loading, not completion form.

## Testing Strategy

1. Static checks
   - `flutter analyze` on touched files.

2. Behavioral checks
   - Complete profile (`+79094189653`, valid email, username, name) -> `/chats`.
   - Missing required field -> `/auth/google-complete`.
   - Forced timeout/error during gate read -> no forced completion redirect; retry flow.

3. Phone mask checks
   - Typing formats visually as `+7 (___) ___-__-__`.
   - Submit stores canonical `+7XXXXXXXXXX`.
   - Existing `+790...` values hydrate without corruption.

## Acceptance Criteria

- Users with complete required fields are not redirected to `/auth/google-complete` due to transient check failures.
- Completion form appears only when required fields are truly incomplete.
- Mobile phone inputs use `+7 (___) ___-__-__` mask in both registration and Google completion forms.
- Stored phone format is canonical and compatible with completeness checks.
