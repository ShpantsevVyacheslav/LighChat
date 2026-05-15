/// Каталог встроенных пресетов рингтонов. Зеркало src/lib/ringtone-presets.ts.
///
/// Каждый пресет существует в двух вариантах:
///   - messages: короткий мягкий одиночный сигнал (~0.5–0.8s)
///   - calls:    длиннее, мелодичный, не режущий слух (~2.5–3s)
///
/// Файлы лежат в:
///   `assets/audio/ringtones/messages/{id}.mp3`
///   `assets/audio/ringtones/calls/{id}.mp3`
///
/// Сгенерированы скриптом scripts/generate-ringtones.py.
enum RingtoneVariant { messages, calls }

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

  String assetPath(RingtoneVariant variant) {
    final folder = variant == RingtoneVariant.messages ? 'messages' : 'calls';
    return 'assets/audio/ringtones/$folder/$fileName';
  }
}

const List<RingtonePreset> kRingtonePresets = <RingtonePreset>[
  RingtonePreset(id: 'classic_chime', fileName: 'classic_chime.mp3', labelKey: 'ringtone_classic_chime'),
  RingtonePreset(id: 'gentle_bells', fileName: 'gentle_bells.mp3', labelKey: 'ringtone_gentle_bells'),
  RingtonePreset(id: 'marimba_tap', fileName: 'marimba_tap.mp3', labelKey: 'ringtone_marimba_tap'),
  RingtonePreset(id: 'soft_pulse', fileName: 'soft_pulse.mp3', labelKey: 'ringtone_soft_pulse'),
  RingtonePreset(id: 'ascending_chord', fileName: 'ascending_chord.mp3', labelKey: 'ringtone_ascending_chord'),
  RingtonePreset(id: 'glass_drop', fileName: 'glass_drop.mp3', labelKey: 'ringtone_glass_drop'),
  RingtonePreset(id: 'wood_block', fileName: 'wood_block.mp3', labelKey: 'ringtone_wood_block'),
  RingtonePreset(id: 'sparkle', fileName: 'sparkle.mp3', labelKey: 'ringtone_sparkle'),
  RingtonePreset(id: 'airy_note', fileName: 'airy_note.mp3', labelKey: 'ringtone_airy_note'),
  RingtonePreset(id: 'tap_tone', fileName: 'tap_tone.mp3', labelKey: 'ringtone_tap_tone'),
];

const String kDefaultMessageRingtoneId = 'classic_chime';

/// Спец-id для мелодии звонка, загружаемой из Firebase Storage
/// (`audio/ringtone.mp3`). Не входит в [kRingtonePresets] — обрабатывается
/// отдельно: см. [ChatCallToneController].
const String kStorageRingtoneId = 'storage_original';

RingtonePreset? ringtonePresetById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final p in kRingtonePresets) {
    if (p.id == id) return p;
  }
  return null;
}

const String kHandRaiseAssetPath = 'assets/audio/conference/hand_raise.mp3';
