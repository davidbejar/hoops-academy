import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/pwa/update_channel.dart';
import 'package:hoops_app/core/pwa/update_providers.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

class FakeUpdateChannel implements UpdateChannel {
  final _ready = StreamController<void>.broadcast();
  int activations = 0;

  void publish() => _ready.add(null);

  @override
  Stream<void> get updateReady => _ready.stream;

  @override
  void activate() => activations++;
}

void main() {
  testWidgets(
    'no prompt until a new service worker is waiting; Reload sends SKIP_WAITING once',
    (tester) async {
      final channel = FakeUpdateChannel();
      final h = Harness(
        me: FakeMeRepository(userWith([tenantNorth])),
        extraOverrides: [updateChannelProvider.overrideWithValue(channel)],
      );
      await h.pump(tester);
      expect(find.byKey(const Key('update-banner')), findsNothing);

      channel.publish();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-banner')), findsOneWidget);
      expect(find.text('Hay una nueva versión disponible'), findsOneWidget);

      await tester.tap(find.byKey(const Key('update-reload')));
      await tester.pump();
      expect(channel.activations, 1);
    },
  );

  test(
    'the controller is false until the channel reports, then stays true',
    () async {
      final channel = FakeUpdateChannel();
      final c = ProviderContainer(
        overrides: [updateChannelProvider.overrideWithValue(channel)],
      );
      addTearDown(c.dispose);
      c.listen(updateAvailableProvider, (_, _) {});
      expect(c.read(updateAvailableProvider), isFalse);
      channel.publish();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(updateAvailableProvider), isTrue);
    },
  );
}
