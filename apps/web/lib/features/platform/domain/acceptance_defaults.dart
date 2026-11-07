/// What the accept form proposes for a request (ADR-0044): the super admin can change every value before sending.
library;

/// A URL-safe academy identifier from its name: lower case, accents dropped, anything else a single hyphen, 3..50
/// characters (the server's slug rule). Empty when the name has too few letters or digits.
String suggestSlug(String academyName) {
  final folded = academyName.toLowerCase().split('').map(_fold).join();
  final hyphenated = folded
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  final cut = hyphenated.length > 50
      ? hyphenated.substring(0, 50).replaceAll(RegExp(r'-+$'), '')
      : hyphenated;
  return cut.length < 3 ? '' : cut;
}

/// The requester's name as given and family name: the first word, then the rest (both empty without a name).
(String, String) splitName(String? name) {
  final words = (name ?? '').trim().split(RegExp(r'\s+'));
  if (words.first.isEmpty) return ('', '');
  return (words.first, words.skip(1).join(' '));
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ñ': 'n', 'ç': 'c',
};

String _fold(String char) => _accents[char] ?? char;
