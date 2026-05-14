import 'package:flutter/material.dart';

/// Паритет с вебом [AudioMessagePlayer.tsx] (`PLAYBACK_RATES`).
const List<double> kAudioMessagePlaybackRates = <double>[
  1.0,
  1.25,
  1.5,
  1.75,
  2.0,
];

const int _kWaveformBarCount = 40;

/// Стабильные «случайные» высоты полос (0.3…1.0), как `useMemo` на вебе.
List<double> audioMessageWaveformBarFactors(String seed) {
  var h = seed.hashCode & 0x7fffffff;
  int next() {
    h = (h * 1103515245 + 12345) & 0x7fffffff;
    return h;
  }

  return List<double>.generate(_kWaveformBarCount, (_) {
    final r = next() % 1000;
    return 0.3 + (r / 1000) * 0.7;
  });
}

/// Волна: прогресс 0…100, цвет = `scheme.primary` (как у play-кнопки).
class AudioMessageWaveformBars extends StatelessWidget {
  const AudioMessageWaveformBars({
    super.key,
    required this.progressPercent,
    required this.seedUrl,
  });

  final double progressPercent;
  final String seedUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bars = audioMessageWaveformBarFactors(seedUrl);
    const barW = 2.0;
    const gap = 1.5;
    const rowH = 32.0;

    // Ячейка фиксированной ширины; внутри Expanded родитель может дать мало места —
    // масштабируем вниз (FittedBox), иначе RenderFlex overflow.
    final rowWidth = bars.length * barW + (bars.length - 1) * gap;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final useW = maxW.isFinite && maxW > 0 ? maxW : rowWidth;
        return SizedBox(
          height: rowH,
          width: useW,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: rowH,
              width: rowWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List<Widget>.generate(bars.length, (i) {
                  final isPlayed = (i / bars.length) * 100 < progressPercent;
                  // Цвет таймлайна = цвет play-кнопки (scheme.primary) одинаково
                  // для своих и входящих — единая визуальная связка «кнопка ↔
                  // таймлайн». Непроигранная часть — та же primary с меньшей
                  // альфой.
                  final barColor = isPlayed
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.35);
                  final hFrac = bars[i];
                  final cellW = barW + (i < bars.length - 1 ? gap : 0);
                  return SizedBox(
                    width: cellW,
                    height: rowH,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: barW,
                        height: rowH * hFrac,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(barW / 2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
