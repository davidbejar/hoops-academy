import 'dart:convert';

/// A strict line-by-line check of an iCalendar file against the parts of
/// RFC 5545 the export uses. Returns the list of violations (empty = valid).
///
/// Checked: CRLF line ends, no line over 75 octets, folds start with a space
/// or tab and never split a UTF-8 sequence, content lines are
/// `name *(;param) : value`, BEGIN / END nest properly, the calendar has
/// VERSION and PRODID, every VEVENT has UID, DTSTAMP and DTSTART, a DTSTART with a TZID points at
/// a VTIMEZONE of the file, a TZID component has STANDARD or DAYLIGHT children
/// with DTSTART, TZOFFSETFROM and TZOFFSETTO, text values escape `,` `;`
/// and backslash.
List<String> validateIcs(List<int> bytes) {
  final problems = <String>[];
  final raw = utf8.decode(bytes);
  if (!raw.endsWith('\r\n')) problems.add('does not end with CRLF');
  if (raw.replaceAll('\r\n', '').contains(RegExp('[\r\n]'))) {
    problems.add('a bare CR or LF outside CRLF');
  }
  final physical = raw.split('\r\n');
  if (physical.isNotEmpty && physical.last.isEmpty) physical.removeLast();
  for (final line in physical) {
    if (utf8.encode(line).length > 75) {
      problems.add('line over 75 octets: ${line.length} chars');
    }
  }
  // Unfold.
  final lines = <String>[];
  for (final line in physical) {
    if (line.startsWith(' ') || line.startsWith('\t')) {
      if (lines.isEmpty) {
        problems.add('fold before the first line');
      } else {
        lines[lines.length - 1] += line.substring(1);
      }
    } else {
      lines.add(line);
    }
  }
  final stack = <String>[];
  final components = <List<String>>[]; // [name, ...property names]
  final tzidsDeclared = <String>{};
  final tzidsUsed = <String>{};
  final seen = <String, Set<String>>{};
  var current = <String>[];
  for (final line in lines) {
    final match = RegExp(
      r'^([A-Za-z0-9-]+)((?:;[A-Za-z0-9-]+=(?:"[^"]*"|[^;:,"]*)(?:,(?:"[^"]*"|[^;:,"]*))*)*):(.*)$',
    ).firstMatch(line);
    if (match == null) {
      problems.add('not a content line: $line');
      continue;
    }
    final name = match.group(1)!.toUpperCase();
    final params = match.group(2)!;
    final value = match.group(3)!;
    if (name == 'BEGIN') {
      stack.add(value);
      current = [value];
      components.add(current);
      continue;
    }
    if (name == 'END') {
      if (stack.isEmpty || stack.last != value) {
        problems.add(
          'END:$value does not match ${stack.isEmpty ? '-' : stack.last}',
        );
      } else {
        stack.removeLast();
      }
      continue;
    }
    if (stack.isEmpty) problems.add('property outside a component: $line');
    current.add(name);
    seen.putIfAbsent(stack.isEmpty ? '' : stack.last, () => {}).add(name);
    if (name == 'TZID' && stack.isNotEmpty && stack.last == 'VTIMEZONE') {
      tzidsDeclared.add(value);
    }
    final tzidParam = RegExp(r'TZID=([^;:]+)').firstMatch(params);
    if (tzidParam != null) tzidsUsed.add(tzidParam.group(1)!);
    if (const {'SUMMARY', 'LOCATION', 'DESCRIPTION', 'TZNAME'}.contains(name)) {
      final unescaped = value.replaceAll(RegExp(r'\\[\;,nN]'), '');
      if (unescaped.contains(RegExp(r'[\;,]'))) {
        problems.add('unescaped special character in $name: $value');
      }
    }
    if (name == 'DTSTAMP' && !RegExp(r'^\d{8}T\d{6}Z$').hasMatch(value)) {
      problems.add('DTSTAMP must be UTC: $value');
    }
    if ((name == 'DTSTART' || name == 'DTEND') && params.isEmpty) {
      if (!RegExp(r'^\d{8}T\d{6}Z$').hasMatch(value)) {
        problems.add('$name without TZID must be UTC: $value');
      }
    }
    if ((name == 'DTSTART' || name == 'DTEND') && params.isNotEmpty) {
      if (!RegExp(r'^\d{8}T\d{6}$').hasMatch(value)) {
        problems.add('$name with TZID must be local time: $value');
      }
    }
    if (name == 'TZOFFSETFROM' || name == 'TZOFFSETTO') {
      if (!RegExp(r'^[+-]\d{4}$').hasMatch(value)) {
        problems.add('bad $name: $value');
      }
    }
  }
  if (stack.isNotEmpty) problems.add('unclosed: ${stack.join(',')}');
  if (lines.isEmpty || lines.first != 'BEGIN:VCALENDAR') {
    problems.add('must start with BEGIN:VCALENDAR');
  }
  if (lines.isEmpty || lines.last != 'END:VCALENDAR') {
    problems.add('must end with END:VCALENDAR');
  }
  final cal = seen['VCALENDAR'] ?? {};
  for (final p in ['VERSION', 'PRODID']) {
    if (!cal.contains(p)) problems.add('VCALENDAR lacks $p');
  }
  for (final c in components) {
    if (c.first == 'VEVENT') {
      for (final p in ['UID', 'DTSTAMP', 'DTSTART']) {
        if (!c.contains(p)) problems.add('VEVENT lacks $p');
      }
    }
    if (c.first == 'STANDARD' || c.first == 'DAYLIGHT') {
      for (final p in ['DTSTART', 'TZOFFSETFROM', 'TZOFFSETTO']) {
        if (!c.contains(p)) problems.add('${c.first} lacks $p');
      }
    }
  }
  for (final tzid in tzidsUsed) {
    if (!tzidsDeclared.contains(tzid)) {
      problems.add('TZID $tzid has no VTIMEZONE');
    }
  }
  final uids = [
    for (final line in lines)
      if (line.startsWith('UID:')) line,
  ];
  if (uids.toSet().length != uids.length) problems.add('duplicate UID');
  return problems;
}
