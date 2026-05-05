import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/energy_saving_preference.dart';
import '../../../l10n/app_localizations.dart';

class EnergySavingScreen extends ConsumerWidget {
  const EnergySavingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(energySavingProvider);
    final notifier = ref.read(energySavingProvider.notifier);

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.energy_saving_title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _ThresholdCard(
              state: state,
              onChanged: (t) => unawaited(notifier.setThreshold(t)),
              dark: dark,
              scheme: scheme,
              fg: fg,
              l10n: l10n,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Text(
                _hintForThreshold(state.threshold, l10n),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: fg.withValues(alpha: 0.62),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                l10n.energy_saving_section_resource_heavy.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: fg.withValues(alpha: 0.55),
                ),
              ),
            ),
            if (state.isLowPowerActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Text(
                  state.systemBatterySaverEnabled
                      ? l10n.energy_saving_active_system
                      : l10n.energy_saving_active_threshold,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8A4D),
                  ),
                ),
              ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: state.isLowPowerActive ? 0.55 : 1.0,
              child: _TogglesCard(
                state: state,
                notifier: notifier,
                dark: dark,
                scheme: scheme,
                fg: fg,
                l10n: l10n,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintForThreshold(
    EnergySavingThreshold t,
    AppLocalizations l10n,
  ) {
    switch (t) {
      case EnergySavingThreshold.off:
        return l10n.energy_saving_hint_off;
      case EnergySavingThreshold.always:
        return l10n.energy_saving_hint_always;
      default:
        return l10n.energy_saving_hint_threshold(t.percent);
    }
  }
}

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({
    required this.state,
    required this.onChanged,
    required this.dark,
    required this.scheme,
    required this.fg,
    required this.l10n,
  });

  final EnergySavingState state;
  final ValueChanged<EnergySavingThreshold> onChanged;
  final bool dark;
  final ColorScheme scheme;
  final Color fg;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = state.threshold;
    final centerText = switch (t) {
      EnergySavingThreshold.off => l10n.energy_saving_threshold_off_full,
      EnergySavingThreshold.always => l10n.energy_saving_threshold_always_full,
      _ => l10n.energy_saving_threshold_at(t.percent),
    };

    return Container(
      decoration: BoxDecoration(
        color: (dark ? Colors.white : scheme.surfaceContainerHighest)
            .withValues(alpha: dark ? 0.06 : 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: fg.withValues(alpha: dark ? 0.12 : 0.10),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.energy_saving_section_mode.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: fg.withValues(alpha: 0.55),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                l10n.energy_saving_threshold_off,
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    centerText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ),
              Text(
                l10n.energy_saving_threshold_always,
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              min: 0,
              max: (EnergySavingThreshold.values.length - 1).toDouble(),
              divisions: EnergySavingThreshold.values.length - 1,
              value: t.index.toDouble(),
              activeColor: scheme.primary,
              onChanged: (v) =>
                  onChanged(EnergySavingThreshold.fromIndex(v.round())),
            ),
          ),
          if (state.batteryLevelPercent != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.energy_saving_current_battery(state.batteryLevelPercent!) +
                    (state.isLowPowerActive
                        ? ' · ${l10n.energy_saving_active_now}'
                        : ''),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: state.isLowPowerActive
                      ? const Color(0xFFFF8A4D)
                      : fg.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TogglesCard extends StatelessWidget {
  const _TogglesCard({
    required this.state,
    required this.notifier,
    required this.dark,
    required this.scheme,
    required this.fg,
    required this.l10n,
  });

  final EnergySavingState state;
  final EnergySavingNotifier notifier;
  final bool dark;
  final ColorScheme scheme;
  final Color fg;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: fg.withValues(alpha: dark ? 0.10 : 0.08),
      indent: 60,
    );

    final rows = <_RowDef>[
      _RowDef(
        icon: Icons.videocam_rounded,
        iconBg: const Color(0xFFFF6E6E),
        title: l10n.energy_saving_autoplay_video_title,
        subtitle: l10n.energy_saving_autoplay_video_subtitle,
        value: state.autoplayVideo,
        onChanged: (v) => unawaited(notifier.setAutoplayVideo(v)),
      ),
      _RowDef(
        icon: Icons.gif_box_rounded,
        iconBg: const Color(0xFFF5A623),
        title: l10n.energy_saving_autoplay_gif_title,
        subtitle: l10n.energy_saving_autoplay_gif_subtitle,
        value: state.autoplayGif,
        onChanged: (v) => unawaited(notifier.setAutoplayGif(v)),
      ),
      _RowDef(
        icon: Icons.emoji_emotions_rounded,
        iconBg: const Color(0xFF4CAF50),
        title: l10n.energy_saving_animated_stickers_title,
        subtitle: l10n.energy_saving_animated_stickers_subtitle,
        value: state.animatedStickers,
        onChanged: (v) => unawaited(notifier.setAnimatedStickers(v)),
      ),
      _RowDef(
        icon: Icons.lightbulb_rounded,
        iconBg: const Color(0xFF26C6DA),
        title: l10n.energy_saving_animated_emoji_title,
        subtitle: l10n.energy_saving_animated_emoji_subtitle,
        value: state.animatedEmoji,
        onChanged: (v) => unawaited(notifier.setAnimatedEmoji(v)),
      ),
      _RowDef(
        icon: Icons.auto_awesome_rounded,
        iconBg: const Color(0xFF4DA2FF),
        title: l10n.energy_saving_interface_animations_title,
        subtitle: l10n.energy_saving_interface_animations_subtitle,
        value: state.interfaceAnimations,
        onChanged: (v) => unawaited(notifier.setInterfaceAnimations(v)),
      ),
      _RowDef(
        icon: Icons.image_rounded,
        iconBg: const Color(0xFF7E57C2),
        title: l10n.energy_saving_media_preload_title,
        subtitle: l10n.energy_saving_media_preload_subtitle,
        value: state.mediaPreload,
        onChanged: (v) => unawaited(notifier.setMediaPreload(v)),
      ),
      _RowDef(
        icon: Icons.access_time_rounded,
        iconBg: const Color(0xFFAB47BC),
        title: l10n.energy_saving_background_update_title,
        subtitle: l10n.energy_saving_background_update_subtitle,
        value: state.backgroundUpdate,
        onChanged: (v) => unawaited(notifier.setBackgroundUpdate(v)),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: (dark ? Colors.white : scheme.surfaceContainerHighest)
            .withValues(alpha: dark ? 0.06 : 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: fg.withValues(alpha: dark ? 0.12 : 0.10),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _SwitchRow(def: rows[i], dark: dark, scheme: scheme, fg: fg),
            if (i < rows.length - 1) divider,
          ],
        ],
      ),
    );
  }
}

class _RowDef {
  const _RowDef({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.def,
    required this.dark,
    required this.scheme,
    required this.fg,
  });

  final _RowDef def;
  final bool dark;
  final ColorScheme scheme;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: def.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(def.icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.94),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  def.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color: fg.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: def.value,
            onChanged: def.onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2F86FF),
          ),
        ],
      ),
    );
  }
}
