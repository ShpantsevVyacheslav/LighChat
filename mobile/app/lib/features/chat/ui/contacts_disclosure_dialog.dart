import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';

const _kPrefsKey = 'contacts_disclosure_v1_accepted';

/// Shows a prominent disclosure dialog (Google Play + App Store requirement)
/// before the app accesses the device contacts for the first time.
///
/// Returns true if the user accepted (or had accepted before).
/// The acceptance is persisted in SharedPreferences and the dialog is
/// never shown again after the first acceptance.
Future<bool> ensureContactsDisclosureAccepted(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kPrefsKey) == true) return true;
  if (!context.mounted) return false;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ContactsDisclosureDialog(),
  );

  if (accepted == true) {
    await prefs.setBool(_kPrefsKey, true);
    return true;
  }
  return false;
}

class _ContactsDisclosureDialog extends StatelessWidget {
  const _ContactsDisclosureDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.contacts_disclosure_title),
      content: Text(
        l10n.contacts_disclosure_body,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.contacts_disclosure_deny),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.contacts_disclosure_allow,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
