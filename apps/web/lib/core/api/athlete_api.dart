/// The generated athlete client (`hoops_athlete_api`). Import it with a
/// prefix (`as ath`): its model names overlap with the core package.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_athlete_api/hoops_athlete_api.dart' as ath;

import '../http/dio_provider.dart';

export 'package:hoops_athlete_api/hoops_athlete_api.dart';

/// Generated client on the app's shared [Dio] (its own interceptors are off).
final athleteApiProvider = Provider<ath.HoopsAthleteApi>(
  (ref) => ath.HoopsAthleteApi(dio: ref.watch(dioProvider), interceptors: const []),
);
