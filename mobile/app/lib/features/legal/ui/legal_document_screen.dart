import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/legal_documents.dart';
import 'markdown_view.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final lang = locale == 'ru' ? 'ru' : 'en';
    final title = legalTitleFor(l10n, slug);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: loadLegalMarkdown(slug: slug, locale: lang),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final body = snap.data;
            if (body == null) {
              return Center(child: Text(l10n.legal_not_found));
            }
            return MarkdownView(markdown: body);
          },
        ),
      ),
    );
  }
}

class LegalIndexScreen extends StatelessWidget {
  const LegalIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.legal_index_title)),
      body: SafeArea(
        child: ListView.separated(
          itemCount: legalSlugs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final slug = legalSlugs[i];
            return ListTile(
              title: Text(legalTitleFor(l10n, slug)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LegalDocumentScreen(slug: slug),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

String legalTitleFor(AppLocalizations l10n, String slug) {
  switch (slug) {
    case 'privacy-policy':
      return l10n.legal_title_privacy_policy;
    case 'terms-of-service':
      return l10n.legal_title_terms_of_service;
    case 'cookie-policy':
      return l10n.legal_title_cookie_policy;
    case 'eula':
      return l10n.legal_title_eula;
    case 'data-processing-agreement':
      return l10n.legal_title_dpa;
    case 'children-policy':
      return l10n.legal_title_children;
    case 'content-moderation-policy':
      return l10n.legal_title_moderation;
    case 'acceptable-use-policy':
      return l10n.legal_title_aup;
    default:
      return slug;
  }
}
