import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../domain/match_event.dart';

/// Bridges the pure-Dart events and the generated `MatchEvent` oneOf through
/// the contract JSON (the generated serializers do the typed mapping).
abstract final class EventCodec {
  static gen.MatchEvent toApi(MatchEvent event) => gen.standardSerializers
      .deserializeWith(gen.MatchEvent.serializer, event.toJson())!;

  static MatchEvent fromApi(gen.MatchEvent event) {
    final json =
        gen.standardSerializers.serializeWith(gen.MatchEvent.serializer, event)!
            as Map;
    return MatchEvent.fromJson(json.cast<String, Object?>());
  }
}
