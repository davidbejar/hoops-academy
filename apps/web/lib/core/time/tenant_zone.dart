import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The academy's IANA time zone. Instants (UTC on the wire) are shown, and
/// dates/times typed by the user are read, in this zone instead of the
/// device's. Without a known zone it behaves like the device zone.
class TenantZone {
  const TenantZone._(this._location, this.label);

  /// Device zone (no academy zone known yet).
  static const TenantZone device = TenantZone._(null, null);

  static bool _initialised = false;

  /// [id] is an IANA id such as `Europe/Madrid`; null / unknown = [device].
  factory TenantZone.of(String? id) {
    if (id == null || id.isEmpty) return device;
    if (!_initialised) {
      tzdata.initializeTimeZones();
      _initialised = true;
    }
    try {
      return TenantZone._(tz.getLocation(id), id);
    } on tz.LocationNotFoundException {
      return device;
    }
  }

  final tz.Location? _location;

  /// The IANA id to show to the user; null when the device zone is used.
  final String? label;

  /// The wall clock of [instant] in this zone, as a plain (local) DateTime.
  DateTime wall(DateTime instant) {
    final location = _location;
    if (location == null) return instant.toLocal();
    final t = tz.TZDateTime.from(instant, location);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  /// The UTC instant at which the wall clock of this zone shows [wall].
  DateTime instant(DateTime wall) {
    final location = _location;
    if (location == null) return wall.toUtc();
    return tz.TZDateTime(
      location,
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
    ).toUtc();
  }

  /// Today's date in this zone given the clock [now] (date only).
  DateTime today(DateTime now) {
    final w = wall(now.toUtc());
    return DateTime(w.year, w.month, w.day);
  }
}
