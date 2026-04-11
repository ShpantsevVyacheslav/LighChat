String messageHtmlToPlainText(String input) {
  var s = input;
  // Normalize common block tags to newlines.
  s = s.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<li\s*>', caseSensitive: false), '• ');

  // Drop all remaining tags.
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');

  // Decode minimal entities we commonly see.
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  // Collapse excessive whitespace/newlines.
  s = s.replaceAll(RegExp(r'\r\n?'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return s.trim();
}

