# Service category icons

4 generic category icons in LighChat premium style — used by
`NavigatorPickerSheet` and `CalendarPickerSheet` to visually mark service
tiles. The brand identity is conveyed by the **label** next to the icon,
not by the icon itself.

| File | Used for |
|---|---|
| `pin.svg` | Map services (Apple Maps, Google Maps, Yandex Maps, 2GIS) |
| `arrow.svg` | Turn-by-turn navigators (Yandex Navi, Waze) |
| `car.svg` | Taxi services (Yandex Go, Uber, inDrive, Citymobil) |
| `calendar.svg` | Calendars (Apple, Google, Yandex, Outlook) |

Each is an original LighChat-designed SVG: rounded square background with
brand-neutral accent gradient + a white category glyph (drop pin / paper-
plane arrow / sedan silhouette / month grid card).

The picker widgets render via `SvgPicture.asset` with a placeholder
fallback to a Material icon. Files can be swapped out with denser/darker
designs without changing any Dart code.
