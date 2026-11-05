//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:hoops_game_api/src/date_serializer.dart';
import 'package:hoops_game_api/src/model/date.dart';

import 'package:hoops_game_api/src/model/assist_event.dart';
import 'package:hoops_game_api/src/model/block_event.dart';
import 'package:hoops_game_api/src/model/box_score.dart';
import 'package:hoops_game_api/src/model/cancel_match_request.dart';
import 'package:hoops_game_api/src/model/create_match_request.dart';
import 'package:hoops_game_api/src/model/foul_event.dart';
import 'package:hoops_game_api/src/model/foul_payload.dart';
import 'package:hoops_game_api/src/model/home_away.dart';
import 'package:hoops_game_api/src/model/match.dart';
import 'package:hoops_game_api/src/model/match_event.dart';
import 'package:hoops_game_api/src/model/match_event_batch.dart';
import 'package:hoops_game_api/src/model/match_event_batch_result.dart';
import 'package:hoops_game_api/src/model/match_event_feed.dart';
import 'package:hoops_game_api/src/model/match_event_rejection_reason.dart';
import 'package:hoops_game_api/src/model/match_event_result.dart';
import 'package:hoops_game_api/src/model/match_event_result_status.dart';
import 'package:hoops_game_api/src/model/match_event_type.dart';
import 'package:hoops_game_api/src/model/match_page.dart';
import 'package:hoops_game_api/src/model/match_roster.dart';
import 'package:hoops_game_api/src/model/match_roster_entry.dart';
import 'package:hoops_game_api/src/model/match_roster_entry_input.dart';
import 'package:hoops_game_api/src/model/match_status.dart';
import 'package:hoops_game_api/src/model/note_event.dart';
import 'package:hoops_game_api/src/model/note_payload.dart';
import 'package:hoops_game_api/src/model/opponent_score_event.dart';
import 'package:hoops_game_api/src/model/opponent_score_payload.dart';
import 'package:hoops_game_api/src/model/page_meta.dart';
import 'package:hoops_game_api/src/model/period_end_event.dart';
import 'package:hoops_game_api/src/model/period_score.dart';
import 'package:hoops_game_api/src/model/period_start_event.dart';
import 'package:hoops_game_api/src/model/person_ref.dart';
import 'package:hoops_game_api/src/model/player_match_line.dart';
import 'package:hoops_game_api/src/model/player_match_stats.dart';
import 'package:hoops_game_api/src/model/player_season_stats.dart';
import 'package:hoops_game_api/src/model/problem.dart';
import 'package:hoops_game_api/src/model/problem_violation.dart';
import 'package:hoops_game_api/src/model/projection_warning.dart';
import 'package:hoops_game_api/src/model/rebound_event.dart';
import 'package:hoops_game_api/src/model/rebound_payload.dart';
import 'package:hoops_game_api/src/model/replace_match_roster_request.dart';
import 'package:hoops_game_api/src/model/score.dart';
import 'package:hoops_game_api/src/model/shot_event.dart';
import 'package:hoops_game_api/src/model/shot_payload.dart';
import 'package:hoops_game_api/src/model/stat_averages.dart';
import 'package:hoops_game_api/src/model/stat_line.dart';
import 'package:hoops_game_api/src/model/steal_event.dart';
import 'package:hoops_game_api/src/model/stored_match_event.dart';
import 'package:hoops_game_api/src/model/sub_in_event.dart';
import 'package:hoops_game_api/src/model/sub_out_event.dart';
import 'package:hoops_game_api/src/model/timeout_event.dart';
import 'package:hoops_game_api/src/model/timeout_payload.dart';
import 'package:hoops_game_api/src/model/turnover_event.dart';
import 'package:hoops_game_api/src/model/update_match_request.dart';
import 'package:hoops_game_api/src/model/usage_report.dart';
import 'package:hoops_game_api/src/model/void_event.dart';
import 'package:hoops_game_api/src/model/void_payload.dart';

part 'serializers.g.dart';

@SerializersFor([
  AssistEvent,
  BlockEvent,
  BoxScore,
  CancelMatchRequest,
  CreateMatchRequest,
  FoulEvent,
  FoulPayload,
  HomeAway,
  Match,
  MatchEvent,
  MatchEventBatch,
  MatchEventBatchResult,
  MatchEventFeed,
  MatchEventRejectionReason,
  MatchEventResult,
  MatchEventResultStatus,
  MatchEventType,
  MatchPage,
  MatchRoster,
  MatchRosterEntry,
  MatchRosterEntryInput,
  MatchStatus,
  NoteEvent,
  NotePayload,
  OpponentScoreEvent,
  OpponentScorePayload,
  PageMeta,
  PeriodEndEvent,
  PeriodScore,
  PeriodStartEvent,
  PersonRef,
  PlayerMatchLine,
  PlayerMatchStats,
  PlayerSeasonStats,
  Problem,
  ProblemViolation,
  ProjectionWarning,
  ReboundEvent,
  ReboundPayload,
  ReplaceMatchRosterRequest,
  Score,
  ShotEvent,
  ShotPayload,
  StatAverages,
  StatLine,
  StealEvent,
  StoredMatchEvent,
  SubInEvent,
  SubOutEvent,
  TimeoutEvent,
  TimeoutPayload,
  TurnoverEvent,
  UpdateMatchRequest,
  UsageReport,
  VoidEvent,
  VoidPayload,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(MatchRosterEntryInput)]),
        () => ListBuilder<MatchRosterEntryInput>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(MatchEvent)]),
        () => ListBuilder<MatchEvent>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(MatchEventResult)]),
        () => ListBuilder<MatchEventResult>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PeriodScore)]),
        () => ListBuilder<PeriodScore>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlayerMatchLine)]),
        () => ListBuilder<PlayerMatchLine>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(StoredMatchEvent)]),
        () => ListBuilder<StoredMatchEvent>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ProjectionWarning)]),
        () => ListBuilder<ProjectionWarning>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(MatchRosterEntry)]),
        () => ListBuilder<MatchRosterEntry>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Match)]),
        () => ListBuilder<Match>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlayerMatchStats)]),
        () => ListBuilder<PlayerMatchStats>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType(int)]),
        () => MapBuilder<String, int>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ProblemViolation)]),
        () => ListBuilder<ProblemViolation>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
