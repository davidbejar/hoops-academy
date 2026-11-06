import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/api/clear_list.dart';

/// ADR-0032: an edit form names every optional field it leaves empty in the request's `clear` list.
void main() {
  test('the empty fields of the form are named', () {
    final clear = clearList({
      ath.UpdateTrainingSessionRequestClearEnum.location: null,
      ath.UpdateTrainingSessionRequestClearEnum.planId: 'plan-1',
      ath.UpdateTrainingSessionRequestClearEnum.notes: null,
    });

    expect(clear!.build(), {
      ath.UpdateTrainingSessionRequestClearEnum.location,
      ath.UpdateTrainingSessionRequestClearEnum.notes,
    });
  });

  test('nothing is sent when every field has a value', () {
    expect(
      clearList({ath.UpdatePlannedAbsenceRequestClearEnum.reason: 'Viaje'}),
      isNull,
    );
  });

  test(
    'a request built with the list sends clear and omits the cleared fields',
    () {
      final request = ath.UpdateTrainingSessionRequest(
        (b) => b
          ..durationMinutes = 60
          ..clear = clearList({
            ath.UpdateTrainingSessionRequestClearEnum.planId: null,
          }),
      );

      final json = ath.standardSerializers.serializeWith(
        ath.UpdateTrainingSessionRequest.serializer,
        request,
      ) as Map;
      expect(json, {
        'durationMinutes': 60,
        'clear': ['planId'],
      });
    },
  );
}
