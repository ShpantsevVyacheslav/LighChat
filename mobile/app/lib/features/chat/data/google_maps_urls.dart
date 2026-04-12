import 'dart:math' as math;

/// Паритет с `src/lib/google-maps.ts`.
String buildGoogleMapsPlaceUrl(double lat, double lng) {
  final safeLat = double.parse(lat.toStringAsFixed(6));
  final safeLng = double.parse(lng.toStringAsFixed(6));
  return 'https://www.google.com/maps?q=$safeLat,$safeLng';
}

/// Встраиваемая карта (без API-ключа).
String buildGoogleMapsEmbedUrl(double lat, double lng, {int zoom = 16}) {
  final safeLat = double.parse(lat.toStringAsFixed(6));
  final safeLng = double.parse(lng.toStringAsFixed(6));
  final z = zoom.clamp(1, 21);
  return 'https://maps.google.com/maps?q=$safeLat,$safeLng&z=$z&output=embed&hl=ru';
}

/// Если при сборке передан `--dart-define=GOOGLE_MAPS_API_KEY=...` (тот же ключ, что
/// `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` на вебе), превью совпадает с десктопом.
String? buildGoogleStaticMapPreviewUrlIfConfigured(
  double lat,
  double lng, {
  int width = 400,
  int height = 225,
}) {
  const key = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  if (key.trim().isEmpty) return null;
  final safeLat = double.parse(lat.toStringAsFixed(6));
  final safeLng = double.parse(lng.toStringAsFixed(6));
  final w = width.clamp(100, 640);
  final h = height.clamp(100, 640);
  return Uri.https('maps.googleapis.com', '/maps/api/staticmap', <String, String>{
    'center': '$safeLat,$safeLng',
    'zoom': '15',
    'size': '${w}x$h',
    'scale': '2',
    'maptype': 'roadmap',
    'markers': 'color:red|$safeLat,$safeLng',
    'key': key.trim(),
  }).toString();
}

/// Один растровый тайл OSM (как в Leaflet): стабильнее, чем `staticmap.openstreetmap.de`
/// в мобильных HTTP-клиентах. Политика тайлов OSM требует идентифицируемый User-Agent при загрузке.
String buildOpenStreetMapTilePreviewUrl(double lat, double lng, {int zoom = 16}) {
  final z = zoom.clamp(0, 19);
  final n = math.pow(2.0, z).toInt();
  var xt = ((lng + 180) / 360 * n).floor();
  xt = xt.clamp(0, n - 1);
  final latRad = lat * math.pi / 180;
  final yFloat =
      (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
          2 *
          n;
  var yt = yFloat.floor();
  yt = yt.clamp(0, n - 1);
  return 'https://tile.openstreetmap.org/$z/$xt/$yt.png';
}

/// Превью для `ChatLocationShare.staticMapUrl`: Google Static (если задан ключ) иначе тайл OSM.
String buildChatLocationStaticPreviewUrl(double lat, double lng) {
  final google = buildGoogleStaticMapPreviewUrlIfConfigured(lat, lng);
  if (google != null && google.isNotEmpty) return google;
  return buildOpenStreetMapTilePreviewUrl(lat, lng);
}

/// Статическое PNG через сторонний staticmap (оставлено для отладки; на iOS часто пусто без UA).
String buildOpenStreetMapStaticPreviewUrl(
  double lat,
  double lng, {
  int width = 400,
  int height = 225,
  int zoom = 15,
}) {
  final la = lat.toStringAsFixed(6);
  final ln = lng.toStringAsFixed(6);
  final w = width.clamp(100, 640);
  final h = height.clamp(100, 640);
  final z = zoom.clamp(8, 18);
  return Uri.https('staticmap.openstreetmap.de', '/staticmap.php', <String, String>{
    'center': '$la,$ln',
    'zoom': '$z',
    'size': '${w}x$h',
    'markers': '$la,$ln,red-pushpin',
  }).toString();
}

/// HTML для WebView: Leaflet + OSM (Google embed часто пустой в WKWebView).
String buildOpenStreetMapLeafletHtml(double lat, double lng, {int zoom = 16}) {
  final la = lat.toStringAsFixed(6);
  final ln = lng.toStringAsFixed(6);
  final z = zoom.clamp(5, 19);
  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>html,body{margin:0;padding:0;height:100%;background:#1a1a1a;}#map{height:100%;width:100%;}</style>
</head>
<body>
<div id="map"></div>
<script>
var map=L.map('map',{zoomControl:true,attributionControl:true}).setView([$la,$ln],$z);
L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{
  maxZoom:19,
  attribution:'&copy; OpenStreetMap'
}).addTo(map);
L.marker([$la,$ln]).addTo(map);
</script>
</body>
</html>
''';
}
