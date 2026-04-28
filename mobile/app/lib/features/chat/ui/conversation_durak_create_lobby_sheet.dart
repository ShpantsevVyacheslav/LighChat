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
  });

  final Map<String, dynamic> initial;

  @override
  State<ConversationDurakCreateLobbySheet> createState() =>
      _ConversationDurakCreateLobbySheetState();
}

class _ConversationDurakCreateLobbySheetState
    extends State<ConversationDurakCreateLobbySheet> {
  late String _mode;
  late int _maxPlayers;
  late bool _withJokers;
  int? _turnTimeSec;

  @override
  void initState() {
    super.initState();
    _mode = (widget.initial['mode'] ?? 'podkidnoy').toString();
    _maxPlayers = (widget.initial['maxPlayers'] is int)
        ? widget.initial['maxPlayers'] as int
        : 6;
    _withJokers = widget.initial['withJokers'] == true;
    _turnTimeSec =
        widget.initial['turnTimeSec'] is int ? widget.initial['turnTimeSec'] as int : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.durak_settings_mode),
              trailing: DropdownButton<String>(
                value: _mode,
                onChanged: (v) => setState(() => _mode = v ?? _mode),
                items: [
                  DropdownMenuItem(
                    value: 'podkidnoy',
                    child: Text(l10n.durak_mode_podkidnoy),
                  ),
                  DropdownMenuItem(
                    value: 'perevodnoy',
                    child: Text(l10n.durak_mode_perevodnoy),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(l10n.durak_settings_max_players),
              trailing: DropdownButton<int>(
                value: _maxPlayers,
                onChanged: (v) => setState(() => _maxPlayers = v ?? _maxPlayers),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 6, child: Text('6')),
                ],
              ),
            ),
            SwitchListTile(
              title: Text(l10n.durak_settings_with_jokers),
              value: _withJokers,
              onChanged: (v) => setState(() => _withJokers = v),
            ),
            ListTile(
              title: Text(l10n.durak_settings_turn_timer),
              trailing: DropdownButton<int?>(
                value: _turnTimeSec,
                onChanged: (v) => setState(() => _turnTimeSec = v),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.durak_turn_timer_off),
                  ),
                  const DropdownMenuItem(value: 30, child: Text('30s')),
                  const DropdownMenuItem(value: 60, child: Text('60s')),
                  const DropdownMenuItem(value: 90, child: Text('90s')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    DurakLobbySettingsResult(<String, dynamic>{
                      'mode': _mode,
                      'maxPlayers': _maxPlayers,
                      'withJokers': _withJokers,
                      'turnTimeSec': _turnTimeSec,
                    }),
                  );
                },
                child: Text(l10n.common_save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

