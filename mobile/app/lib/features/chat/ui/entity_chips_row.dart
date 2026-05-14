import 'package:flutter/material.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

import '../data/chat_haptics.dart';
import '../data/local_entity_extractor.dart';

/// Ряд кликабельных «чипов» под сообщением — quick-actions для
/// распознанных сущностей (телефон → позвонить, адрес → карта,
/// email → mailto и т.п.). Лениво подгружает ML Kit модель при первом
/// сообщении на этом языке.
///
/// Показывается только если ML Kit нашёл хотя бы одну actionable-сущность.
/// На пустом / не-actionable тексте — ничего не рендерится.
class EntityChipsRow extends StatefulWidget {
  const EntityChipsRow({
    super.key,
    required this.text,
    required this.languageHint,
    required this.isMine,
  });

  final String text;
  final String languageHint;
  final bool isMine;

  @override
  State<EntityChipsRow> createState() => _EntityChipsRowState();
}

class _EntityChipsRowState extends State<EntityChipsRow> {
  List<EntityAnnotation>? _annotations;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant EntityChipsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.languageHint != widget.languageHint) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final res = await LocalEntityExtractor.instance.annotate(
      widget.text,
      languageHint: widget.languageHint,
    );
    if (!mounted) return;
    setState(() => _annotations = res);
  }

  @override
  Widget build(BuildContext context) {
    final ann = _annotations;
    if (ann == null || ann.isEmpty) return const SizedBox.shrink();

    // Берём только actionable-типы и убираем дубли (одинаковый text+type).
    final seen = <String>{};
    final chips = <_EntityChipData>[];
    for (final a in ann) {
      for (final e in a.entities) {
        final icon = _iconFor(e.type);
        if (icon == null) continue;
        final key = '${e.type.name}|${a.text}';
        if (!seen.add(key)) continue;
        chips.add(_EntityChipData(
          annotation: a,
          entity: e,
          icon: icon,
          color: entityTypeColor(e.type),
        ));
      }
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips
            .map((c) => _EntityChip(data: c, isMine: widget.isMine))
            .toList(),
      ),
    );
  }

  IconData? _iconFor(EntityType t) {
    switch (t) {
      case EntityType.phone:
        return Icons.call_rounded;
      case EntityType.email:
        return Icons.mail_outline_rounded;
      case EntityType.address:
        return Icons.location_on_outlined;
      case EntityType.dateTime:
        return Icons.event_outlined;
      case EntityType.url:
        return Icons.open_in_new_rounded;
      case EntityType.flightNumber:
        return Icons.flight_takeoff_rounded;
      case EntityType.iban:
        return Icons.account_balance_outlined;
      case EntityType.trackingNumber:
        return Icons.local_shipping_outlined;
      default:
        return null;
    }
  }
}

class _EntityChipData {
  const _EntityChipData({
    required this.annotation,
    required this.entity,
    required this.icon,
    required this.color,
  });
  final EntityAnnotation annotation;
  final Entity entity;
  final IconData icon;
  final Color color;
}

class _EntityChip extends StatelessWidget {
  const _EntityChip({required this.data, required this.isMine});
  final _EntityChipData data;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = isMine ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ChatHaptics.instance.tick();
          await LocalEntityExtractor.instance.launchEntity(data.annotation);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: data.color.withValues(alpha: 0.36),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 13, color: data.color),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  data.annotation.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg.withValues(alpha: 0.92),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
