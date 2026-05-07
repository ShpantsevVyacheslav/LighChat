import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

import '../data/app_language_preference.dart';
import '../../../l10n/app_localizations.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(appLanguagePreferenceProvider);

    void setPref(AppLanguagePreference next) {
      unawaited(
        ref.read(appLanguagePreferenceProvider.notifier).setPreference(next),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;

    Widget row({required AppLanguagePreference value, required String title}) {
      return RadioListTile<AppLanguagePreference>(
        value: value,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.92),
          ),
        ),
        activeColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_language_title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: (dark ? Colors.white : scheme.surfaceContainerHighest)
                    .withValues(alpha: dark ? 0.06 : 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: fg.withValues(alpha: dark ? 0.12 : 0.10),
                ),
              ),
              child: RadioGroup<AppLanguagePreference>(
                groupValue: current,
                onChanged: (v) {
                  if (v == null) return;
                  setPref(v);
                },
                child: Column(
                  children: [
                    // «Системный» — первый, потом все конкретные локали.
                    row(
                      value: AppLanguagePreference.system,
                      title: l10n.settings_language_system,
                    ),
                    for (final pref in AppLanguagePreference.values)
                      if (pref != AppLanguagePreference.system) ...[
                        Divider(
                          height: 1,
                          color: fg.withValues(alpha: dark ? 0.12 : 0.10),
                        ),
                        row(value: pref, title: pref.nativeName),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.settings_language_hint_system,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: fg.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
