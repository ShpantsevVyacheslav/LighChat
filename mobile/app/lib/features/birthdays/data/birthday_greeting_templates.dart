import 'package:lighchat_mobile/l10n/app_localizations.dart';

/// 5 готовых шаблонов поздравлений. Плейсхолдер `{name}` подставляется
/// именем именинника в момент отправки. Тексты живут в ARB-словарях, мы
/// лишь собираем их в массив на нужной локали.
List<String> birthdayGreetingTemplates(AppLocalizations l10n, String name) {
  return <String>[
    l10n.birthday_template_1(name),
    l10n.birthday_template_2(name),
    l10n.birthday_template_3(name),
    l10n.birthday_template_4(name),
    l10n.birthday_template_5(name),
  ];
}
