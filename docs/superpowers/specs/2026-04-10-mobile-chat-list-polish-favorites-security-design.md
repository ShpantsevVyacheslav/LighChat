# Mobile Chat List Polish + Favorites Shortcut + Security Design

## Context

User reported six issues in mobile chat UX and data visibility:

1. Need tighter top spacing to fit one extra dialog card in viewport.
2. Profile menu sheet is too transparent.
3. Remove `Нижнее меню` section from chat settings screen.
4. Chat history scroll jumps down when loading older messages.
5. Search row in chat list is too tall.
6. Extra bottom air under bottom navigation buttons.

Additionally:

- Add `Избранное` entry in chat folders as web-like shortcut (not real folder), opening saved-messages chat directly.
- If saved chat does not exist, auto-create and open it.
- Ensure users cannot see other users' saved-messages chats (security-level guarantee).
- Improve avatar behavior for auto-assigned chats in list.

## Goals

- Increase effective chat list density without harming readability.
- Align favorites behavior with web.
- Enforce privacy for saved-messages conversations on rules level.
- Keep scroll position stable when paging older messages.

## Scope

In scope:

- Mobile UI spacing/tone refinements in chat list and menu sheet.
- Favorites pseudo-folder shortcut and auto-create/open logic.
- Firestore rules hardening for saved-messages read access.
- Avatar fallback improvements in chat list items.
- Scroll anchor fix for older-history loading.

Out of scope:

- Full redesign of all folder UX.
- New data model fields.
- Broad chat architecture refactor.

## Selected Approach

Apply targeted UI/behavior fixes in mobile screens and add strict security checks in both `firestore.rules` and `src/firestore.rules` to prevent cross-user saved-chat visibility.

Why:

- Fastest path to user-visible improvement.
- Minimal risk to unrelated chat functionality.
- Security issue is closed at backend policy level (not only client filtering).

## Design

### 1) Chat list compactness updates

Files:

- `mobile/app/lib/features/chat/ui/chat_list_screen.dart`
- `mobile/app/lib/features/chat/ui/chat_folder_bar.dart`

Changes:

- Remove unnecessary top spacing and tighten filter block paddings.
- Reduce search input height and vertical paddings.
- Slightly reduce bottom nav bottom margin/safe-area buffer so buttons sit closer to lower edge.

Expected result: one additional chat card often fits in same viewport on common iPhone/Android heights.

### 2) Profile menu opacity tuning

File:

- `mobile/app/lib/features/chat/ui/chat_account_menu_sheet.dart`

Changes:

- Increase surface opacity and border contrast for sheet and row cards.
- Keep visual style (glass-like) but reduce background bleed-through significantly.

### 3) Remove `Нижнее меню` section from chat settings

File:

- `mobile/app/lib/features/chat/ui/chat_settings_screen.dart`

Changes:

- Remove heading/cards and related save actions for `bottomNavAppearance` from this screen.
- Keep persisted value untouched in Firestore (no migration required).

### 4) Favorites pseudo-folder shortcut (web parity)

Files:

- `mobile/app/lib/features/chat/ui/chat_list_screen.dart`
- `mobile/app/lib/features/chat/data/saved_messages_chat.dart`
- `mobile/packages/lighchat_firebase/lib/src/chat_repository.dart` (or equivalent service already used for saved chat creation)

Behavior:

- Add first folder chip `Избранное` in folder bar.
- It does not filter list; tap immediately resolves saved-messages conversation for current user.
- If absent, create saved chat and then navigate to `/chats/{id}`.

### 5) Security hardening for saved chats

Files:

- `firestore.rules`
- `src/firestore.rules`

Rule intent:

- Saved chat pattern (`participantIds.size() == 1`) must only be readable by that participant.
- Preserve existing member-based access for regular chats/groups.

This must remain synchronized in both rules files.

### 6) Avatar fallback improvements

Files:

- `mobile/app/lib/features/chat/ui/chat_list_screen.dart`
- `mobile/app/lib/features/chat/ui/chat_list_item.dart`

Behavior:

- For direct chats, prefer `profile.avatarThumb/avatar`, then `conversation.participantInfo[otherId].avatarThumb/avatar`, then initials.
- For group chats, use `conversation.photoUrl` if present; otherwise stable initials placeholder.

### 7) Scroll anchoring on history paging

File:

- `mobile/app/lib/features/chat/ui/chat_screen.dart`

Behavior:

- When older messages are loaded, preserve viewport anchor by compensating with max-scroll delta.
- No jump to bottom/newest while user is reading old messages at top edge.

## Error Handling

- Favorites auto-create failure: show snackbar, remain on list screen.
- Rules hardening may reveal previously leaked saved-chat docs as permission-denied; client should ignore and continue rendering allowed conversations.
- Avatar URL failures fallback to placeholder initials without throwing.

## Testing Strategy

1. Manual UX checks
   - Chat list top block and search are visually tighter.
   - Bottom nav lower padding reduced.
   - Profile menu sheet is less transparent.
   - `Нижнее меню` section absent in chat settings.

2. Favorites flow
   - Tap `Избранное` opens existing saved chat.
   - If absent, it is auto-created and opened.

3. Security checks
   - User A cannot read User B saved chat doc even if ID is known.
   - Regular direct/group chat visibility unchanged.

4. Scroll behavior
   - Scroll to very top in long chat and trigger history load.
   - View remains anchored near previous content, no jump to newest message.

## Acceptance Criteria

- Chat list is denser and shows more dialogs per viewport.
- Profile menu readability improved due to lower transparency.
- `Нижнее меню` block removed from chat settings screen.
- Favorites pseudo-folder opens/creates saved chat directly.
- Saved chats are not readable by non-owners due to Firestore rules.
- Auto-assigned chats show avatar fallback correctly.
- Loading older messages no longer bounces user to latest message.
