# Mobile Chat Load + Avatar Menu + Profile Page Parity Design

## Context

Current mobile app has three related UX gaps:

1. After successful auth, user can land on a blank/empty chat screen instead of seeing chats or explicit empty state.
2. Bottom navigation does not include user avatar entry opening the account menu like web.
3. Dedicated profile page with web-like structure is missing.

User requested parity direction based on provided web screenshots.

## Goals

- Ensure authenticated users always see deterministic chat screen state (list or clear empty state), never opaque blank screen.
- Add avatar entry in bottom nav with account menu behavior similar to web.
- Implement mobile profile page with core editable fields and save/cancel flow.

## Scope

In scope:

- Chat list loading/empty-state stabilization.
- Avatar item in mobile bottom nav + bottom-sheet menu.
- New `/profile` route and profile edit screen.
- In menu, only `Профиль` and `Выйти` are fully functional now; remaining items are visible with `Скоро` semantics.

Out of scope:

- Full implementation of all web menu destinations (chat settings/admin/notifications/privacy/theme).
- Deep visual 1:1 parity for every spacing token across all dashboard surfaces.
- Backend schema changes.

## Selected Approach

Deliver a vertical slice that solves usability blockers first and preserves room for incremental parity:

- Harden chat-list loading states.
- Add avatar menu affordance that users expect from web.
- Add profile page with core edit fields and existing validation/normalization.

This provides immediate value with lower regression risk than implementing all menu destinations at once.

## Design

### 1) Chat list loading stabilization

Affected area:

- `mobile/app/lib/features/chat/ui/chat_list_screen.dart`

Behavior changes:

- If auth is ready and profile gate is not deterministically `incomplete`, render chat list pipeline.
- If chat index/conversations are empty, show explicit empty state (CTA: create/new chat) instead of blank background.
- Keep retry path active (`Повторить`) and re-invalidate providers on demand.

Acceptance behavior:

- No silent blank screen after successful login.
- User sees either populated list or clear empty-state block.

### 2) Bottom nav avatar entry + account menu

Affected area:

- `mobile/app/lib/features/chat/ui/chat_bottom_nav.dart`
- helper extraction if needed: `mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart`

Behavior changes:

- Add avatar button as right-most nav item.
- On tap, open bottom sheet with account card and menu rows.
- Working rows:
  - `Профиль` -> route `/profile`
  - `Выйти` -> signOut + route `/auth`
- Non-working rows remain visible and show `Скоро` (or disabled appearance) to match requested partial parity.

Visual direction:

- Reuse current glass/background style language already present in chat UI.
- Avatar uses thumb URL with initials fallback.

### 3) Profile page implementation

Affected area:

- New route in `mobile/app/lib/app_router.dart`: `/profile`
- New screen: `mobile/app/lib/features/auth/ui/profile_screen.dart` (or feature/profile equivalent)

Fields:

- `name`
- `username`
- `email`
- `phone` (masked `+7 (___) ___-__-__`, canonical save `+7XXXXXXXXXX`)
- `dateOfBirth` (optional)
- `bio` (optional)
- avatar update block (existing avatar cropper reuse)

Actions:

- `Отмена` restores original values.
- `Сохранить` validates and updates user profile via existing mobile firebase service path.

Validation rules:

- Reuse existing validators from auth forms.
- No new completeness criteria introduced.

## Error Handling

- Profile fetch/save failures show inline error text in screen.
- Menu actions catch signOut failures and show user-friendly message.
- Empty chat source errors render readable error widgets (not silent blank state).

## Testing Strategy

1. Static checks
   - `flutter analyze` on changed files.

2. Manual behavior checks
   - Login with account that has chats -> chat list visible.
   - Login with account without chats -> explicit empty state visible.
   - Tap avatar in bottom nav -> account menu opens.
   - Menu `Профиль` opens profile screen.
   - Edit/save profile updates Firestore-visible values.
   - Menu `Выйти` signs out and returns to `/auth`.

3. Regression checks
   - Existing chat open flow remains functional.
   - Google completion flow remains reachable when genuinely required.

## Acceptance Criteria

- Authenticated users no longer land on opaque blank chat surface.
- Bottom nav includes avatar icon/button.
- Avatar tap opens account menu matching requested structure.
- `Профиль` and `Выйти` in menu are fully functional.
- `/profile` page exists with editable core fields and save/cancel actions.
