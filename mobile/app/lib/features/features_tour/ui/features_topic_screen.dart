import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/features_data.dart';
import 'feature_mocks.dart';

class FeaturesTopicScreen extends StatelessWidget {
  const FeaturesTopicScreen({super.key, required this.topicId});
  final FeatureTopicId topicId;

  @override
  Widget build(BuildContext context) {
    final content = featuresContentFor(Localizations.localeOf(context));
    final meta = featureTopicMetaFor(topicId);
    final t = content.topics[topicId]!;
    final scheme = Theme.of(context).colorScheme;
    final related = kFeatureTopics.where((m) => m.id != topicId).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Tagline pill
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: meta.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(meta.icon, size: 14, color: meta.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(t.tagline,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: meta.accent)),
              ),
            ]),
          ),
          Text(t.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 8),
          Text(t.summary,
              style: TextStyle(
                  fontSize: 14, height: 1.45, color: scheme.onSurface.withValues(alpha: 0.7))),
          if (meta.ctaPath != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.go(meta.ctaPath!),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(t.ctaLabel),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FeatureMockFrame(child: buildFeatureMockFor(topicId)),
          const SizedBox(height: 24),
          Row(children: [
            Icon(Icons.lightbulb_outline_rounded, size: 18, color: meta.accent),
            const SizedBox(width: 6),
            Text(content.helpfulTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          for (final s in t.sections)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.55),
                border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(s.body,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: scheme.onSurface.withValues(alpha: 0.78))),
                  if (s.bullets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final b in s.bullets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: meta.accent, borderRadius: BorderRadius.circular(999))),
                            Expanded(
                              child: Text(b,
                                  style: const TextStyle(fontSize: 13, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Icon(Icons.checklist_rounded, size: 18, color: meta.accent),
            const SizedBox(width: 6),
            Text(content.howToTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          for (var i = 0; i < t.howTo.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.55),
                border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: meta.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: meta.accent)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(t.howTo[i], style: const TextStyle(fontSize: 13, height: 1.4)),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 16),
          Text(content.relatedTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final r in related) _RelatedCard(meta: r, content: content),
        ],
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.meta, required this.content});
  final FeatureTopicMeta meta;
  final FeaturesContent content;

  @override
  Widget build(BuildContext context) {
    final t = content.topics[meta.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.replace('/features/${meta.id.slug}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: meta.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(meta.icon, color: meta.accent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(t.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}
