/**
 * Ссылки на карты. Для превью нужен ключ Static Maps API в NEXT_PUBLIC_GOOGLE_MAPS_API_KEY.
 * Открыть в приложении можно и без ключа: {@link buildGoogleMapsEmbedUrl}, {@link buildGoogleMapsPlaceUrl}.
 */
export function buildGoogleMapsPlaceUrl(lat: number, lng: number): string {
  const safeLat = Number(lat.toFixed(6));
  const safeLng = Number(lng.toFixed(6));
  return `https://www.google.com/maps?q=${safeLat},${safeLng}`;
}

/**
 * URL для встраивания карты в iframe (без ключа API). Используется во внутреннем диалоге LighChat.
 */
export function buildGoogleMapsEmbedUrl(lat: number, lng: number, zoom = 16): string {
  const safeLat = Number(lat.toFixed(6));
  const safeLng = Number(lng.toFixed(6));
  const z = Math.min(Math.max(Math.round(zoom), 1), 21);
  return `https://maps.google.com/maps?q=${safeLat},${safeLng}&z=${z}&output=embed&hl=ru`;
}

export function buildGoogleStaticMapUrl(
  lat: number,
  lng: number,
  width: number,
  height: number
): string | null {
  const key = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
  if (!key || !key.trim()) return null;
  const safeLat = Number(lat.toFixed(6));
  const safeLng = Number(lng.toFixed(6));
  const w = Math.min(Math.max(Math.round(width), 100), 640);
  const h = Math.min(Math.max(Math.round(height), 100), 640);
  const params = new URLSearchParams({
    center: `${safeLat},${safeLng}`,
    zoom: '15',
    size: `${w}x${h}`,
    scale: '2',
    maptype: 'roadmap',
    markers: `color:red|${safeLat},${safeLng}`,
    key: key.trim(),
  });
  return `https://maps.googleapis.com/maps/api/staticmap?${params.toString()}`;
}
