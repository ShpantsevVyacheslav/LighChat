import 'user_profile.dart';

/// Как web `isAnonymousPlaceholderEmail` (`registration-index-keys`).
bool isAnonymousPlaceholderEmail(String? email) {
  final e = (email ?? '').trim().toLowerCase();
  return e.endsWith('@anonymous.com') && e.startsWith('guest_');
}

bool isEligibleRegisteredChatUser(UserProfile p) {
  if (p.deletedAt != null && p.deletedAt!.trim().isNotEmpty) return false;
  if (isAnonymousPlaceholderEmail(p.email)) return false;
  return true;
}

/// Web `isUserListedInGlobalChatSearch`.
bool isUserListedInGlobalChatSearch(UserProfile viewer, UserProfile candidate) {
  if (viewer.role == 'admin') return true;
  return candidate.privacySettings?.showInGlobalUserSearch != false;
}

int _sortUsersByNameRu(UserProfile a, UserProfile b) {
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Уже отфильтрованный список: контакты, затем глобальный поиск с учётом privacy.
({List<UserProfile> fromContacts, List<UserProfile> fromGlobal})
splitUsersByContactsAndGlobalVisibility({
  required List<UserProfile> matched,
  required UserProfile viewer,
  required List<String> contactIds,
}) {
  final set = contactIds.toSet();
  final fromContacts = matched.where((u) => set.contains(u.id)).toList()
    ..sort(_sortUsersByNameRu);
  final fromGlobal = matched
      .where((u) => !set.contains(u.id) && isUserListedInGlobalChatSearch(viewer, u))
      .toList()
    ..sort(_sortUsersByNameRu);
  return (fromContacts: fromContacts, fromGlobal: fromGlobal);
}

// --- ru-latin parity (web `ru-latin-search-normalize.ts`) ---

const Map<String, String> _cyrToLat = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'е': 'e',
  'ё': 'e',
  'ж': 'zh',
  'з': 'z',
  'и': 'i',
  'й': 'y',
  'к': 'k',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'ts',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'sch',
  'ъ': '',
  'ы': 'y',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};

const List<(String, String)> _latinMulti = [
  ('sch', 'щ'),
  ('sh', 'ш'),
  ('ch', 'ч'),
  ('zh', 'ж'),
  ('ts', 'ц'),
  ('kh', 'х'),
  ('yu', 'ю'),
  ('ya', 'я'),
  ('yo', 'ё'),
  ('ye', 'е'),
];

const Map<String, String> _latinSingle = {
  'a': 'а',
  'b': 'б',
  'v': 'в',
  'w': 'в',
  'g': 'г',
  'd': 'д',
  'e': 'е',
  'z': 'з',
  'i': 'и',
  'y': 'й',
  'j': 'й',
  'k': 'к',
  'l': 'л',
  'm': 'м',
  'n': 'н',
  'o': 'о',
  'p': 'п',
  'r': 'р',
  's': 'с',
  't': 'т',
  'u': 'у',
  'f': 'ф',
  'h': 'х',
  'x': 'кс',
  'c': 'к',
  'q': 'к',
};

final RegExp _hasCyr = RegExp(r'[а-яё]', caseSensitive: false);
final RegExp _hasLat = RegExp(r'[a-z]', caseSensitive: false);

String _cyrillicToLatin(String input) {
  final s = input.toLowerCase();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    b.write(_cyrToLat[ch] ?? ch);
  }
  return b.toString();
}

String _latinToCyrillic(String input) {
  final s = input.toLowerCase();
  final b = StringBuffer();
  var i = 0;
  while (i < s.length) {
    var matched = false;
    for (final (lat, cyr) in _latinMulti) {
      if (s.startsWith(lat, i)) {
        b.write(cyr);
        i += lat.length;
        matched = true;
        break;
      }
    }
    if (matched) continue;
    final c = s[i];
    b.write(_latinSingle[c] ?? c);
    i++;
  }
  return b.toString();
}

List<String> _haystackSearchVariants(String text) {
  final t = text.trim().toLowerCase();
  if (t.isEmpty) return const [];
  final set = <String>{t};
  if (_hasCyr.hasMatch(t)) {
    final lat = _cyrillicToLatin(t);
    if (lat.isNotEmpty && lat != t) set.add(lat);
  }
  if (_hasLat.hasMatch(t)) {
    final cyr = _latinToCyrillic(t);
    if (cyr.isNotEmpty && cyr != t) set.add(cyr);
  }
  return set.toList();
}

List<String> _querySearchNeedles(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final set = <String>{q};
  if (_hasCyr.hasMatch(q)) {
    final lat = _cyrillicToLatin(q);
    if (lat.isNotEmpty && lat != q) set.add(lat);
  }
  if (_hasLat.hasMatch(q)) {
    final cyr = _latinToCyrillic(q);
    if (cyr.isNotEmpty && cyr != q) set.add(cyr);
  }
  return set.where((e) => e.isNotEmpty).toList();
}

/// Web `ruEnSubstringMatch`.
bool ruEnSubstringMatch(String haystack, String needle) {
  final needles = _querySearchNeedles(needle);
  if (needles.isEmpty) return true;
  final hays = _haystackSearchVariants(haystack);
  for (final hay in hays) {
    for (final n in needles) {
      if (n.isNotEmpty && hay.contains(n)) return true;
    }
  }
  return false;
}

/// Web `userMatchesChatSearchQuery` для [UserProfile].
bool userMatchesChatSearchQuery(UserProfile user, String query) {
  final q = query.trim();
  if (q.isEmpty) return true;
  if (user.name.isNotEmpty && ruEnSubstringMatch(user.name, q)) return true;
  final un = (user.username ?? '').trim().toLowerCase();
  if (un.isNotEmpty) {
    final needle = (q.startsWith('@') ? q.substring(1) : q).trim();
    if (needle.isNotEmpty && ruEnSubstringMatch(un, needle)) return true;
  }
  return false;
}

String? atUsernameLabel(String? username) {
  var h = (username ?? '').trim();
  if (h.startsWith('@')) h = h.substring(1);
  return h.isNotEmpty ? '@$h' : null;
}
