/// Каталог встроенных пресетов рингтонов. Зеркало src/lib/ringtone-presets.ts:
/// id и имена файлов синхронизированы между web и mobile. Файлы лежат в
/// assets/audio/ringtones/ и assets/audio/conference/.
///
/// Сгенерированы скриптом scripts/generate-ringtones.py.
class RingtonePreset {
  const RingtonePreset({
    required this.id,
    required this.fileName,
    required this.labelKey,
  });

  final String id;
  final String fileName;

  /// Ключ локализации для отображаемого имени пресета.
  final String labelKey;

  String get assetPath => 'assets/audio/ringtones/$fileName';
}

const List<RingtonePreset> kRingtonePresets = <RingtonePreset>[
  RingtonePreset(id: 'classic_chime', fileName: 'classic_chime.mp3', labelKey: 'ringtone_classic_chime'),
  RingtonePreset(id: 'gentle_bells', fileName: 'gentle_bells.mp3', labelKey: 'ringtone_gentle_bells'),
  RingtonePreset(id: 'marimba_tap', fileName: 'marimba_tap.mp3', labelKey: 'ringtone_marimba_tap'),
  RingtonePreset(id: 'soft_pulse', fileName: 'soft_pulse.mp3', labelKey: 'ringtone_soft_pulse'),
  RingtonePreset(id: 'ascending_chord', fileName: 'ascending_chord.mp3', labelKey: 'ringtone_ascending_chord'),
];

const String kDefaultMessageRingtoneId = 'classic_chime';

RingtonePreset? ringtonePresetById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final p in kRingtonePresets) {
    if (p.id == id) return p;
  }
  return null;
}

const String kHandRaiseAssetPath = 'assets/audio/conference/hand_raise.mp3';
