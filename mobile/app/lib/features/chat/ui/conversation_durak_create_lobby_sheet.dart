import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class DurakLobbySettingsResult {
  const DurakLobbySettingsResult(this.settings);
  final Map<String, dynamic> settings;
}

class ConversationDurakCreateLobbySheet extends StatefulWidget {
  const ConversationDurakCreateLobbySheet({
    super.key,
    required this.initial,
    required this.isGroup,
  });

  final Map<String, dynamic> initial;
  final bool isGroup;

  @override
  State<ConversationDurakCreateLobbySheet> createState() =>
      _ConversationDurakCreateLobbySheetState();
}

class _ConversationDurakCreateLobbySheetState
    extends State<ConversationDurakCreateLobbySheet> {
  late String _mode;
  late int _maxPlayers;
  late int _deckSize;
  late bool _withJokers;
  int? _turnTimeSec;
  late String _throwInPolicy;
  late bool _shulerEnabled;

  @override
  void initState() {
    super.initState();
    _mode = (widget.initial['mode'] ?? 'podkidnoy').toString();
    _maxPlayers = (widget.initial['maxPlayers'] is int)
        ? widget.initial['maxPlayers'] as int
        : 6;
    if (!widget.isGroup) _maxPlayers = 2;
    _deckSize = (widget.initial['deckSize'] is int)
        ? widget.initial['deckSize'] as int
        : 36;
    _withJokers = widget.initial['withJokers'] == true;
    _turnTimeSec = widget.initial['turnTimeSec'] is int
        ? widget.initial['turnTimeSec'] as int
        : 15;
    _throwInPolicy = (widget.initial['throwInPolicy'] ?? 'all').toString();
    _shulerEnabled = widget.initial['shulerEnabled'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardColor = const Color(0xFF131D2B);
    final borderColor = Colors.white.withValues(alpha: 0.10);
    final subtitleColor = Colors.white.withValues(alpha: 0.66);

    Widget section({
      required String title,
      String? subtitle,
      required Widget child,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            if (subtitle != null && subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: subtitleColor,
                  height: 1.25,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Material(
        color: const Color(0xFF0C1320),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.conversation_games_durak,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  children: [
                    section(
                      title: l10n.durak_settings_mode,
                      child: _DurakSegmented<String>(
                        value: _mode,
                        items: [
                          ('podkidnoy', l10n.durak_mode_podkidnoy),
                          ('perevodnoy', l10n.durak_mode_perevodnoy),
                        ],
                        onChanged: (v) => setState(() => _mode = v),
                      ),
                    ),
                    const SizedBox(height: 10),
                    section(
                      title: l10n.durak_settings_deck,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DurakSegmented<int>(
                            value: _deckSize,
                            items: [
                              (36, l10n.durak_deck_36),
                              (52, l10n.durak_deck_52),
                            ],
                            onChanged: (v) => setState(() => _deckSize = v),
                          ),
                          const SizedBox(height: 10),
                          _DurakSwitchTile(
                            title: l10n.durak_settings_with_jokers,
                            value: _withJokers,
                            onChanged: (v) => setState(() => _withJokers = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    section(
                      title: l10n.durak_settings_throw_in_policy,
                      child: _DurakSegmented<String>(
                        value: _throwInPolicy,
                        items: [
                          ('all', l10n.durak_throw_in_policy_all),
                          ('neighbors', l10n.durak_throw_in_policy_neighbors),
                        ],
                        onChanged: (v) => setState(() => _throwInPolicy = v),
                      ),
                    ),
                    const SizedBox(height: 10),
                    section(
                      title: l10n.durak_settings_shuler,
                      subtitle: l10n.durak_settings_shuler_subtitle,
                      child: _DurakSwitchTile(
                        title: l10n.durak_settings_shuler,
                        value: _shulerEnabled,
                        onChanged: (v) => setState(() => _shulerEnabled = v),
                      ),
                    ),
                    if (widget.isGroup) ...[
                      const SizedBox(height: 10),
                      section(
                        title: l10n.durak_settings_max_players,
                        child: _DurakSegmented<int>(
                          value: _maxPlayers,
                          items: const [
                            (2, '2'),
                            (3, '3'),
                            (4, '4'),
                            (5, '5'),
                            (6, '6'),
                          ],
                          onChanged: (v) => setState(() => _maxPlayers = v),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    section(
                      title: l10n.durak_settings_turn_timer,
                      subtitle: l10n.durak_create_timer_subtitle,
                      child: _DurakSegmented<int?>(
                        value: _turnTimeSec,
                        items: [
                          (null, l10n.durak_turn_timer_off),
                          (15, '15s'),
                          (10, '10s'),
                          (20, '20s'),
                          (30, '30s'),
                          (60, '60s'),
                        ],
                        onChanged: (v) => setState(() => _turnTimeSec = v),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            DurakLobbySettingsResult(<String, dynamic>{
                              'mode': _mode,
                              'maxPlayers': _maxPlayers,
                              'deckSize': _deckSize,
                              'withJokers': _withJokers,
                              'turnTimeSec': _turnTimeSec,
                              'throwInPolicy': _throwInPolicy,
                              'shulerEnabled': _shulerEnabled,
                            }),
                          );
                        },
                        child: Text(
                          l10n.common_save,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurakSegmented<T> extends StatelessWidget {
  const _DurakSegmented({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1622),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _DurakSegmentedItem<T>(
                  selected: item.$1 == value,
                  label: item.$2,
                  onTap: () => onChanged(item.$1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DurakSegmentedItem<T> extends StatelessWidget {
  const _DurakSegmentedItem({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF7FD8E1).withValues(alpha: 0.32)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.82),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DurakSwitchTile extends StatelessWidget {
  const _DurakSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
