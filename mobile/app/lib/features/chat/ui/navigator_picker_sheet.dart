import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../../l10n/app_localizations.dart';
import '../data/chat_haptics.dart';

/// Premium bottom-sheet выбора навигатора при тапе по адресу-чипу.
/// Показывает только реально установленные на устройстве приложения.
///
/// Поддержка: Apple Maps (iOS) / Google Maps / Яндекс Карты / Яндекс
/// Навигатор / 2ГИС / Waze. На Android запросы к canLaunchUrl для
/// неустановленных приложений ведут себя предсказуемо (требуется
/// `<queries>` в AndroidManifest для package visibility).
class NavigatorPickerSheet {
  NavigatorPickerSheet._();

  static Future<void> show({
    required BuildContext context,
    required String address,
  }) async {
    final encoded = Uri.encodeComponent(address);
    final apps = await _availableApps(encoded);
    if (apps.isEmpty) {
      // Fallback: Apple Maps на iOS / geo:// на Android.
      final fallback = Platform.isIOS
          ? Uri.parse('http://maps.apple.com/?q=$encoded')
          : Uri.parse('geo:0,0?q=$encoded');
      await url_launcher.launchUrl(
        fallback,
        mode: url_launcher.LaunchMode.externalApplication,
      );
      return;
    }
    // Если установлен ровно один навигатор — открываем сразу, без шита.
    if (apps.length == 1) {
      await _launch(apps.first.url);
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _PickerContent(
        address: address,
        apps: apps,
      ),
    );
  }

  static Future<List<_NavApp>> _availableApps(String encoded) async {
    final out = <_NavApp>[];

    // Apple Maps — присутствует на каждом iOS, не требует canLaunch.
    if (Platform.isIOS) {
      out.add(_NavApp(
        id: 'apple_maps',
        label: 'Apple Maps',
        icon: Icons.map_outlined,
        color: const Color(0xFF34A853),
        url: 'http://maps.apple.com/?q=$encoded',
      ));
    }

    // Google Maps — `comgooglemaps://?q=<addr>` на iOS, иначе HTTPS.
    final gmapsCheck = Platform.isIOS
        ? Uri.parse('comgooglemaps://')
        : Uri.parse('https://maps.google.com/');
    if (await _canLaunch(gmapsCheck)) {
      out.add(_NavApp(
        id: 'google_maps',
        label: 'Google Maps',
        icon: Icons.directions_rounded,
        color: const Color(0xFF1A73E8),
        url: Platform.isIOS
            ? 'comgooglemaps://?q=$encoded&directionsmode=transit'
            : 'https://www.google.com/maps/dir/?api=1&destination=$encoded',
      ));
    }

    // Яндекс Карты.
    if (await _canLaunch(Uri.parse('yandexmaps://'))) {
      out.add(_NavApp(
        id: 'yandex_maps',
        label: 'Яндекс Карты',
        icon: Icons.location_on_rounded,
        color: const Color(0xFFFF3333),
        url: 'yandexmaps://maps.yandex.ru/?text=$encoded',
      ));
    }

    // Яндекс Навигатор.
    if (await _canLaunch(Uri.parse('yandexnavi://'))) {
      out.add(_NavApp(
        id: 'yandex_navi',
        label: 'Яндекс Навигатор',
        icon: Icons.navigation_rounded,
        color: const Color(0xFFFFCC00),
        url: 'yandexnavi://build_route_on_map?lat_to=0&lon_to=0&text=$encoded',
      ));
    }

    // 2GIS.
    if (await _canLaunch(Uri.parse('dgis://'))) {
      out.add(_NavApp(
        id: 'dgis',
        label: '2ГИС',
        icon: Icons.place_outlined,
        color: const Color(0xFF6FCF5C),
        url: 'dgis://2gis.ru/search/$encoded',
      ));
    }

    // Waze.
    if (await _canLaunch(Uri.parse('waze://'))) {
      out.add(_NavApp(
        id: 'waze',
        label: 'Waze',
        icon: Icons.alt_route_rounded,
        color: const Color(0xFF33CCFF),
        url: 'waze://?q=$encoded',
      ));
    }

    // === Taxi ===

    // Яндекс Go (бывш. Yandex Taxi).
    if (await _canLaunch(Uri.parse('yandextaxi://'))) {
      out.add(_NavApp(
        id: 'yandex_go',
        label: 'Яндекс Go',
        icon: Icons.local_taxi_rounded,
        color: const Color(0xFFFFCC00),
        url: 'yandextaxi://route?end-address=$encoded&appmetrica_tracking_id=1178268795219780156',
      ));
    }

    // Uber.
    if (await _canLaunch(Uri.parse('uber://'))) {
      out.add(_NavApp(
        id: 'uber',
        label: 'Uber',
        icon: Icons.local_taxi_outlined,
        color: const Color(0xFF000000),
        url: 'uber://?action=setPickup&pickup=my_location'
            '&dropoff[formatted_address]=$encoded',
      ));
    }

    // inDrive.
    if (await _canLaunch(Uri.parse('indriver://'))) {
      out.add(_NavApp(
        id: 'indrive',
        label: 'inDrive',
        icon: Icons.directions_car_rounded,
        color: const Color(0xFFC4FF00),
        url: 'indriver://',
      ));
    }

    // Citymobil — нет официальной схемы, открываем веб-fallback только
    // если установлено приложение (схема `citymobil://`).
    if (await _canLaunch(Uri.parse('citymobil://'))) {
      out.add(_NavApp(
        id: 'citymobil',
        label: 'Ситимобил',
        icon: Icons.local_taxi_rounded,
        color: const Color(0xFF00B86B),
        url: 'citymobil://',
      ));
    }

    return out;
  }

  static Future<bool> _canLaunch(Uri uri) async {
    try {
      return await url_launcher.canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}

class _NavApp {
  const _NavApp({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.url,
  });
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String url;
}

class _PickerContent extends StatelessWidget {
  const _PickerContent({required this.address, required this.apps});
  final String address;
  final List<_NavApp> apps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bg = isDark ? const Color(0xFF15171C) : const Color(0xFFF5F6F8);
    final fg = isDark ? const Color(0xFFEDEEF2) : const Color(0xFF14161A);
    final fgMuted = isDark
        ? const Color(0xFFA0A4AD)
        : const Color(0xFF5C6470);
    final cardBg = isDark ? const Color(0xFF1E2127) : Colors.white;
    final border = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x0F000000);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: bg.withValues(alpha: 0.96),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: fgMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C8DFF).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Color(0xFF7C8DFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.navigator_picker_title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: fg,
                              ),
                            ),
                            Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: fgMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...apps.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _NavTile(
                          app: a,
                          isDark: isDark,
                          cardBg: cardBg,
                          border: border,
                          fg: fg,
                          onTap: () async {
                            Navigator.of(context).maybePop();
                            unawaited(ChatHaptics.instance.selectionChanged());
                            await NavigatorPickerSheet._launch(a.url);
                          },
                        ),
                      )),
                  const SizedBox(height: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: address));
                        unawaited(ChatHaptics.instance.success());
                        if (context.mounted) Navigator.of(context).maybePop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: cardBg,
                          border: Border.all(color: border, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.copy_all_rounded,
                              size: 18,
                              color: fg,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.voice_transcript_copy,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.app,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.fg,
    required this.onTap,
  });
  final _NavApp app;
  final bool isDark;
  final Color cardBg;
  final Color border;
  final Color fg;
  final Future<void> Function() onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed ? 0.97 : 1,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTap(),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.app.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(widget.app.icon, color: widget.app.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.app.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.fg,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: widget.fg.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
