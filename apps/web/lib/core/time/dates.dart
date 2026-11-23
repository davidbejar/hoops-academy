/// The one home of date text and date conversions (WEB-04).
///
/// Wire dates (`yyyy-MM-dd`, forms, file names) are plain ISO text; what the
/// user reads is either the locale's own `yMMMd` ([displayDate]) or, for the
/// training and health screens, the compact `dd/MM/yyyy` ([fullDate]). The
/// three generated clients each have their own `Date` class, so the
/// conversions are one per client. Pure Dart (no Flutter), so the export
/// builders can use it.
library;

import 'package:hoops_athlete_api/hoops_athlete_api.dart' as ath show Date;
// ignore: implementation_imports
import 'package:hoops_core_api/src/model/date.dart' as api show Date;
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin show Date;
import 'package:intl/intl.dart';

/// Two digits, zero padded: `07`.
String twoDigits(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` from its parts.
String isoDateOf(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-${twoDigits(month)}-${twoDigits(day)}';

/// `yyyy-MM-dd`.
String isoDate(DateTime d) => isoDateOf(d.year, d.month, d.day);

/// `yyyyMMdd`, the day in a file name.
String compactDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${twoDigits(d.month)}${twoDigits(d.day)}';

/// `yyyy-MM-dd` of a core contract date.
String formatDate(api.Date d) => isoDateOf(d.year, d.month, d.day);

/// `dd/MM`.
String shortDate(DateTime d) => '${twoDigits(d.day)}/${twoDigits(d.month)}';

/// `dd/MM/yyyy` from an athlete contract date.
String fullDate(ath.Date d) =>
    '${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year}';

/// `dd/MM/yy`: the axis and tooltip text of the charts.
String chartDate(DateTime d) =>
    '${twoDigits(d.day)}/${twoDigits(d.month)}/${twoDigits(d.year % 100)}';

/// The locale's own short date, e.g. `10 nov 2026`; [locale] is a language tag.
String displayDate(String locale, DateTime d) =>
    DateFormat.yMMMd(locale).format(d);

/// [displayDate] and the `HH:mm` that follows it.
String displayDateTime(String locale, DateTime d) =>
    DateFormat.yMMMd(locale).add_Hm().format(d);

/// The day of [d] (its year, month and day) as each generated client's `Date`.
api.Date toApiDate(DateTime d) => api.Date(d.year, d.month, d.day);
ath.Date toAthDate(DateTime d) => ath.Date(d.year, d.month, d.day);
fin.Date toFinDate(DateTime d) => fin.Date(d.year, d.month, d.day);
