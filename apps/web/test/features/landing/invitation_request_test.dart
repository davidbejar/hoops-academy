import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/landing/domain/invitation_request.dart';

void main() {
  group('InvitationRequest.problems', () {
    test('a complete request has no problems; the name is optional', () {
      const request = InvitationRequest(
        name: '',
        email: 'ana@club.es',
        role: InvitationRole.coach,
        academy: 'Club Norte',
      );
      expect(request.problems, isEmpty);
    });

    test('an empty request misses the e-mail, the role and the academy', () {
      const request = InvitationRequest(name: '', email: '', academy: '');
      expect(request.problems, {
        InvitationProblem.invalidEmail,
        InvitationProblem.missingRole,
        InvitationProblem.missingAcademy,
      });
    });

    test('a blank academy name counts as missing', () {
      const request = InvitationRequest(
        name: 'Ana',
        email: 'ana@club.es',
        role: InvitationRole.parent,
        academy: '   ',
      );
      expect(request.problems, {InvitationProblem.missingAcademy});
    });
  });

  group('isValidEmail', () {
    test('accepts ordinary addresses, trimmed', () {
      expect(isValidEmail('ana@club.es'), isTrue);
      expect(isValidEmail('  coach.one+u12@hoops-academy.com '), isTrue);
    });

    test('rejects addresses without a domain, with spaces or two @', () {
      for (final bad in [
        '',
        'ana',
        'ana@',
        'ana@club',
        'a b@club.es',
        'a@b@c.es',
      ]) {
        expect(isValidEmail(bad), isFalse, reason: bad);
      }
    });
  });

  test('players cannot request an invitation (decision 51)', () {
    expect(InvitationRole.values, [
      InvitationRole.admin,
      InvitationRole.coach,
      InvitationRole.parent,
    ]);
  });
}
