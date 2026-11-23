/// `hoops-<academy-slug>-<what>-<yyyyMMdd>.<ext>`, ASCII only, so the
/// `download` attribute is safe on every platform (and it matches the server
/// exports' `Content-Disposition`).
library;

import '../time/dates.dart' show compactDate;

String exportFileName({
  required String slug,
  required String what,
  required DateTime date,
  required String extension,
}) {
  final academy = asciiSlug(slug);
  return 'hoops-${academy.isEmpty ? 'academy' : academy}-${asciiSlug(what)}'
      '-${compactDate(date)}.$extension';
}

/// Lower-case `a-z0-9` words joined by single dashes; Latin accents fold to
/// their base letter, anything else is a separator.
String asciiSlug(String input) {
  final folded = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final at = _accented.indexOf(ch);
    folded.write(at < 0 ? (ch == 'ß' ? 'ss' : ch) : _plain[at]);
  }
  return folded
      .toString()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

const _accented = 'áàâäãåÁÀÂÄÃÅéèêëÉÈÊËíìîïÍÌÎÏóòôöõøÓÒÔÖÕØúùûüÚÙÛÜñÑçÇýÿÝ';
const _plain = 'aaaaaaAAAAAAeeeeEEEEiiiiIIIIooooooOOOOOOuuuuUUUUnNcCyyY';
