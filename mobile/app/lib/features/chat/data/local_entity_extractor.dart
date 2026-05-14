import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// On-device выделение сущностей в тексте через ML Kit (~3 МБ модели,
/// скачиваются один раз с mlkit.gstatic.com при первом использовании).
///
/// Поддерживается: телефонные номера, email, адреса, даты, трек-номера,
/// IBAN, номера рейсов, ISBN, ссылки. iOS + Android.
///
/// Цель — подсветить в пузыре сообщения сущности и сделать их кликабельными
/// (тап → Telephone.app / Mail / Maps / Calendar и т.д.).
class LocalEntityExtractor {
  LocalEntityExtractor._();
  static final LocalEntityExtractor instance = LocalEntityExtractor._();

  /// Лениво создаваемые экстракторы по языку.
  final Map<EntityExtractorLanguage, EntityExtractor> _instances =
      <EntityExtractorLanguage, EntityExtractor>{};

  final EntityExtractorModelManager _modelManager =
      EntityExtractorModelManager();

  /// Memo кеш по `(text-hash, lang)` чтобы не дёргать ML Kit на каждый
  /// rebuild сообщения.
  final Map<String, List<EntityAnnotation>> _cache =
      <String, List<EntityAnnotation>>{};

  /// Аннотирует строку. Возвращает аннотации в порядке появления.
  /// На пустом тексте / неподдерживаемом языке — пустой список.
  Future<List<EntityAnnotation>> annotate(
    String text, {
    required String languageHint,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    final lang = _mapLanguage(languageHint);
    if (lang == null) return const [];

    final key = '${lang.name}|${trimmed.length}|${trimmed.hashCode}';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      // Лениво качаем модель — отдельный ModelManager.
      if (!await _modelManager.isModelDownloaded(lang.name)) {
        await _modelManager.downloadModel(lang.name, isWifiRequired: false);
      }
      final extractor = _instances.putIfAbsent(
        lang,
        () => EntityExtractor(language: lang),
      );
      final annotations = await extractor.annotateText(trimmed);
      _cache[key] = annotations;
      return annotations;
    } catch (_) {
      return const [];
    }
  }

  /// Открыть «правильную» нативную ссылку для типа сущности:
  /// телефон → `tel:`, email → `mailto:`, адрес → Maps, дата → пока копируем,
  /// ссылка → внешний браузер.
  Future<bool> launchEntity(EntityAnnotation annotation) async {
    for (final e in annotation.entities) {
      final uri = _uriFor(e, annotation.text);
      if (uri == null) continue;
      try {
        return await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } catch (_) {/* try next */}
    }
    return false;
  }

  Uri? _uriFor(Entity entity, String rawText) {
    switch (entity.type) {
      case EntityType.phone:
        final raw = (entity as PhoneEntity).rawValue;
        return Uri(scheme: 'tel', path: raw);
      case EntityType.email:
        return Uri(scheme: 'mailto', path: rawText);
      case EntityType.url:
        return Uri.tryParse(rawText.startsWith('http')
            ? rawText
            : 'https://$rawText');
      case EntityType.address:
        final q = Uri.encodeComponent(rawText);
        if (Platform.isIOS) {
          return Uri.parse('http://maps.apple.com/?q=$q');
        }
        return Uri.parse('geo:0,0?q=$q');
      case EntityType.flightNumber:
        return Uri.parse(
            'https://www.google.com/search?q=${Uri.encodeComponent(rawText)}');
      default:
        return null;
    }
  }

  /// Минимальный mapping IETF → ML Kit. ML Kit поддерживает ограниченный
  /// набор языков; для незнакомых возвращаем `null` (UI не подсветит).
  EntityExtractorLanguage? _mapLanguage(String hint) {
    final h = hint.toLowerCase().split('-').first.split('_').first;
    switch (h) {
      case 'en':
        return EntityExtractorLanguage.english;
      case 'ru':
        return EntityExtractorLanguage.russian;
      case 'es':
        return EntityExtractorLanguage.spanish;
      case 'pt':
        return EntityExtractorLanguage.portuguese;
      case 'tr':
        return EntityExtractorLanguage.turkish;
      case 'de':
        return EntityExtractorLanguage.german;
      case 'fr':
        return EntityExtractorLanguage.french;
      case 'it':
        return EntityExtractorLanguage.italian;
      case 'pl':
        return EntityExtractorLanguage.polish;
      case 'ar':
        return EntityExtractorLanguage.arabic;
      case 'ja':
        return EntityExtractorLanguage.japanese;
      case 'ko':
        return EntityExtractorLanguage.korean;
      case 'zh':
        return EntityExtractorLanguage.chinese;
      case 'nl':
        return EntityExtractorLanguage.dutch;
      default:
        return null;
    }
  }
}

/// Локализованное имя типа сущности — для tooltip / menu в UI.
String entityTypeLabel(EntityType t) {
  switch (t) {
    case EntityType.phone:
      return 'Phone';
    case EntityType.email:
      return 'Email';
    case EntityType.address:
      return 'Address';
    case EntityType.dateTime:
      return 'Date';
    case EntityType.url:
      return 'Link';
    case EntityType.flightNumber:
      return 'Flight';
    case EntityType.iban:
      return 'IBAN';
    case EntityType.isbn:
      return 'ISBN';
    case EntityType.trackingNumber:
      return 'Tracking';
    case EntityType.money:
      return 'Money';
    case EntityType.paymentCard:
      return 'Card';
    default:
      return '';
  }
}

/// Подсказка, какой цвет акцента отрисовать под сущностью.
Color entityTypeColor(EntityType t) {
  switch (t) {
    case EntityType.phone:
      return const Color(0xFF6FCF97);
    case EntityType.email:
      return const Color(0xFF7C8DFF);
    case EntityType.url:
      return const Color(0xFF56CCF2);
    case EntityType.address:
      return const Color(0xFFFFA94D);
    case EntityType.dateTime:
      return const Color(0xFFFFD166);
    case EntityType.flightNumber:
      return const Color(0xFFB39DFF);
    default:
      return const Color(0xFFB39DFF);
  }
}
