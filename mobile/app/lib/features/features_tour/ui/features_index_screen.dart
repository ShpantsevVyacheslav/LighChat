import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../platform/native_nav_bar/nav_bar_config.dart';
import '../../../platform/native_nav_bar/native_nav_scaffold.dart';
import '../data/features_data.dart';
import 'feature_mocks.dart';

class FeaturesIndexScreen extends StatelessWidget {
  const FeaturesIndexScreen({super.key, this.fromWelcome = false});
  final bool fromWelcome;

  @override
  Widget build(BuildContext context) {
    final content = featuresContentFor(Localizations.localeOf(context));
    final l10n = AppLocalizations.of(context)!;
    final highlights = kFeatureTopics.where((m) => m.highlight).toList();
    final others = kFeatureTopics.where((m) => !m.highlight).toList();

    return NativeNavScaffold(
      top: NavBarTopConfig(title: NavBarTitle(title: content.pageTitle)),
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/chats');
        }
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (fromWelcome)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: featureAccentPrimary.withValues(alpha: 0.10),
                  border: Border.all(color: featureAccentPrimary.withValues(alpha: 0.30)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome, size: 12, color: featureAccentPrimary),
                  const SizedBox(width: 4),
                  Text(content.fromWelcomeBadge,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: featureAccentPrimary)),
                ]),
              ),
            ),
          Text(content.heroPrimary,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 8),
          Text(content.heroSecondary,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65))),
          const SizedBox(height: 14),
          // CTA «Смотреть тур» — открывает FeaturesShowreelScreen с озвучкой
          // через flutter_tts (на iOS — AVSpeechSynthesizer premium voice).
          FilledButton.icon(
            onPressed: () => context.push('/features/showreel'),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(content.showreelCta),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
          Text(content.highlightTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(content.highlightSubtitle,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          for (final m in highlights) _BigTopicCard(meta: m, content: content),
          const SizedBox(height: 24),
          Text(content.moreTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(content.moreSubtitle,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          for (final m in others) _SmallTopicCard(meta: m, content: content),
          if (fromWelcome)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: () => context.go('/chats'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.meeting_back_to_chats),
              ),
            ),
        ],
      ),
    );
  }
}

class _BigTopicCard extends StatelessWidget {
  const _BigTopicCard({required this.meta, required this.content});
  final FeatureTopicMeta meta;
  final FeaturesContent content;

  @override
  Widget build(BuildContext context) {
    final t = content.topics[meta.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/features/${meta.id.slug}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureMockFrame(child: buildFeatureMockFor(meta.id)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: meta.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(meta.icon, color: meta.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(t.tagline,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_outward_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallTopicCard extends StatelessWidget {
  const _SmallTopicCard({required this.meta, required this.content});
  final FeatureTopicMeta meta;
  final FeaturesContent content;

  @override
  Widget build(BuildContext context) {
    final t = content.topics[meta.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/features/${meta.id.slug}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: meta.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.icon, color: meta.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(t.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ),
      ),
    );
  }
}
