# Service brand icons

Place square PNG/SVG logos (≥128×128 PNG, transparent background recommended)
of each external service we deeplink to. Files are picked up by
`NavigatorPickerSheet` and `CalendarPickerSheet` via the `assetPath` field —
if a file with the expected name exists, it's rendered via `Image.asset`
inside a 38–40pt rounded tile; otherwise the widget falls back to the
current Material icon.

Expected filenames (lower_snake_case + `.png`):

Maps & Navigation:
- `apple_maps.png`
- `google_maps.png`
- `yandex_maps.png`
- `yandex_navi.png`
- `2gis.png`
- `waze.png`

Taxi:
- `yandex_go.png`
- `uber.png`
- `indrive.png`
- `citymobil.png`

Calendars:
- `apple_calendar.png`
- `google_calendar.png`
- `yandex_calendar.png`
- `outlook_calendar.png`

License note: use only logos from the corresponding service's
press-kit / brand guidelines page. Each brand is the trademark of
its owner; we use icons solely as link affordances to the respective
services.
