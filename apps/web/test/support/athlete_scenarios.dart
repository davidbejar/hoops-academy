import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/training/domain/week.dart';

import 'core_fixtures.dart';
import 'fake_athlete.dart';
import 'fake_repos.dart';

/// Monday of the current week (what the calendar opens on).
DateTime get monday => startOfWeek(DateTime.now());

DateTime weekday(int offset) => DateTime(monday.year, monday.month, monday.day + offset);

/// Two teams, a roster for t1 and the players used by the athlete tests.
FakeCore athleteCore() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [team('t1', 'Mini A', alias: 'Leones', players: 3), team('t2', 'Infantil B', cat: u14, players: 1)],
    rosters: {
      't1': [teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7'), teamPlayer('t1', 'p2', 'Leo Gil', jersey: '10'), teamPlayer('t1', 'p3', 'Mia Soto')],
      't2': [teamPlayer('t2', 'p4', 'Dan Lopez')],
    },
  ),
  players: FakePlayersRepository([
    player('p1', 'Ana Ruiz', cat: u12, teams: [assignment('t1', 'Mini A', jersey: '7')]),
    player('p2', 'Leo Gil', cat: u12, teams: [assignment('t1', 'Mini A', jersey: '10')]),
    player('p3', 'Mia Soto', cat: u12, teams: [assignment('t1', 'Mini A')]),
    player('p4', 'Dan Lopez', cat: u14, teams: [assignment('t2', 'Infantil B')]),
  ]),
);

FakeAthlete weekAthlete() => FakeAthlete(
  training: FakeTrainingRepository(
    sessions: [
      session('s1', day: weekday(1), hour: 18, planId: 'plan-1', notes: 'Traer botella'),
      session('s2', day: weekday(3), hour: 19, minutes: 60),
      session('s3', day: weekday(3), hour: 17, teamId: 't2', location: null),
      session('s4', day: weekday(5), hour: 10, status: ath.TrainingSessionStatus.CANCELLED, cancelReason: 'Lluvia'),
    ],
  ),
  plans: FakePlansRepository(plans: [
    planOf('plan-1', 'Tiro básico', items: [planItem('i1', 'Calentamiento', 0, minutes: 10), planItem('i2', 'Tiros libres', 1, minutes: 20, sets: 3, reps: 10)]),
  ]),
);
