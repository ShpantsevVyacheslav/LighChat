# Mobile Auth Logo Parity With Web

## Context

Flutter auth screens currently use a single image wordmark (`assets/lighchat_wordmark.png`) that does not match the active web auth branding. Web auth uses a separate brand mark image (`/brand/lighchat-mark.png`) plus a styled `LighChat` wordmark text with two-tone coloring.

Goal: make Flutter auth branding match web auth composition and visual hierarchy.

## Scope

In scope:

- Update Flutter auth header on sign-in screen to web-equivalent composition.
- Apply same auth header on Google profile completion screen.
- Reuse existing mark asset (`assets/lighchat_mark.png`) as source of truth for logo mark.

Out of scope:

- Reworking full auth card layout, spacing system, or background effects.
- Replacing typography app-wide.
- Brand updates outside auth flow.

## Selected Approach

Use a shared Flutter auth brand header widget and replace the old single wordmark image usage.

Reasoning:

- Matches web semantics (mark + text, not baked image).
- Avoids duplication between two auth screens.
- Keeps future updates isolated to one widget.

## Design

### Component structure

Create `mobile/app/lib/features/auth/ui/auth_brand_header.dart`:

- `AuthBrandHeader` stateless widget.
- Top block: `Image.asset('assets/lighchat_mark.png')` with constrained square size and `BoxFit.contain`.
- Bottom block: `RichText` (or `Text.rich`) for `LighChat`.
  - `Ligh` in `#1E3A5F` (dark theme fallback may use lighter equivalent for contrast).
  - `Chat` in `#E9967A`.
  - Weight/size tuned to current auth card proportions.
- Vertical spacing equivalent to current web header rhythm.

### Integration points

Replace current top logo blocks in:

- `mobile/app/lib/features/auth/ui/auth_screen.dart`
- `mobile/app/lib/features/auth/ui/google_complete_profile_screen.dart`

Both screens render `AuthBrandHeader` at the same location currently occupied by `assets/lighchat_wordmark.png`.

### Visual parity requirements

- Use `assets/lighchat_mark.png` (web-equivalent mark source).
- Wordmark is text-based and two-tone, not image-based.
- Header must remain centered and fit small mobile heights without clipping.
- Preserve existing auth flow controls and interaction behavior.

## Error handling

- If mark asset is missing at runtime, Flutter image error should not crash app; the rest of auth screen remains functional.
- No change to auth logic, validation, or routing.

## Testing strategy

1. Static checks
   - `flutter analyze` for mobile app.

2. Visual verification
   - Open `/auth` flow and confirm header composition matches web concept (mark + two-tone `LighChat`).
   - Open `/auth/google-complete` and confirm identical header treatment.
   - Validate on compact and tall screens (no overlap with card contents).

3. Regression checks
   - Confirm sign-in and Google continuation buttons remain unchanged.
   - Confirm no new overflow warnings in debug console on auth screens.

## Acceptance criteria

- Mobile auth no longer displays single `lighchat_wordmark.png` at top.
- Mobile auth uses `lighchat_mark.png` plus two-tone `LighChat` text.
- Both sign-in and Google profile completion screens use the same header component.
- No behavioral/auth routing regressions.
