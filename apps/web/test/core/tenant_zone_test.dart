import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/time/tenant_zone.dart';

void main() {
  test('wall() shows an instant in the academy zone, instant() inverts it', () {
    final zone = TenantZone.of('Asia/Jakarta'); // UTC+7, no DST
    final instant = DateTime.utc(2026, 11, 5, 18, 30);
    final wall = zone.wall(instant);
    expect([wall.year, wall.month, wall.day, wall.hour, wall.minute], [2026, 11, 6, 1, 30]);
    expect(zone.instant(wall), instant);
    expect(zone.instant(wall).isUtc, isTrue);
  });

  test('follows daylight saving of the zone', () {
    final zone = TenantZone.of('Europe/Madrid');
    expect(zone.wall(DateTime.utc(2026, 7, 1, 12)).hour, 14); // CEST
    expect(zone.wall(DateTime.utc(2026, 12, 1, 12)).hour, 13); // CET
    expect(zone.instant(DateTime(2026, 7, 1, 14)), DateTime.utc(2026, 7, 1, 12));
  });

  test('unknown or missing zone falls back to the device zone, without a label', () {
    for (final z in [TenantZone.of('Mars/Olympus'), TenantZone.of(null), TenantZone.of('')]) {
      expect(z.label, isNull);
      final i = DateTime.utc(2026, 11, 5, 18, 30);
      expect(z.wall(i), i.toLocal());
    }
    expect(TenantZone.of('Asia/Jakarta').label, 'Asia/Jakarta');
  });
}
