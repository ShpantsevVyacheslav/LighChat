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
    _turnTimeSec =
        widget.initial['turnTimeSec'] is int ? widget.initial['turnTimeSec'] as int : null;
    _throwInPolicy = (widget.initial['throwInPolicy'] ?? 'all').toString();
    _shulerEnabled = widget.initial['shulerEnabled'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.70,
        minChildSize: 0.40,
        maxChildSize: 0.92,
        builder: (context, controller) {
          final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              );
          final sectionStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              );

          Widget section(String title, Widget child) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: sectionStyle),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            );
          }

          Widget segmented<T>({
            required T value,
            required List<(T, String)> items,
            required void Function(T v) onChanged,
          }) {
            return LayoutBuilder(
              builder: (context, c) {
                return SegmentedButton<T>(
                  segments: [
                    for (final it in items) ButtonSegment<T>(value: it.$1, label: Text(it.$2)),
                  ],
                  selected: {value},
                  onSelectionChanged: (s) => onChanged(s.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              },
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.conversation_games_durak, style: titleStyle),
                const SizedBox(height: 4),
                Text(
                  l10n.conversation_games_durak_subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 12),

                section(
                  l10n.durak_settings_mode,
                  segmented<String>(
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
                  l10n.durak_settings_deck,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      segmented<int>(
                        value: _deckSize,
                        items: [
                          (36, l10n.durak_deck_36),
                          (52, l10n.durak_deck_52),
                        ],
                        onChanged: (v) => setState(() => _deckSize = v),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.durak_settings_with_jokers),
                        value: _withJokers,
                        onChanged: (v) => setState(() => _withJokers = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                section(
                  l10n.durak_settings_throw_in_policy,
                  segmented<String>(
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
                  l10n.durak_settings_shuler,
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.durak_settings_shuler),
                    subtitle: Text(l10n.durak_settings_shuler_subtitle),
                    value: _shulerEnabled,
                    onChanged: (v) => setState(() => _shulerEnabled = v),
                  ),
                ),
                const SizedBox(height: 10),

                section(
                  l10n.durak_settings_max_players,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isGroup)
                        Text(
                          'DM: только 2 игрока',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                        ),
                      const SizedBox(height: 8),
                      segmented<int>(
                        value: _maxPlayers,
                        items: const [
                          (2, '2'),
                          (3, '3'),
                          (4, '4'),
                          (5, '5'),
                          (6, '6'),
                        ],
                        onChanged: (v) => setState(() => _maxPlayers = widget.isGroup ? v : 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                section(
                  l10n.durak_settings_turn_timer,
                  segmented<int?>(
                    value: _turnTimeSec,
                    items: [
                      (null, l10n.durak_turn_timer_off),
                      (30, '30s'),
                      (60, '60s'),
                      (90, '90s'),
                    ],
                    onChanged: (v) => setState(() => _turnTimeSec = v),
                  ),
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
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
                    child: Text(l10n.common_save),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

