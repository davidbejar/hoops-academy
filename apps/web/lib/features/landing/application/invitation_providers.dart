import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../data/invitation_repository.dart';

/// The landing's invitation sender; tests override it with a fake.
final invitationRepositoryProvider = Provider<InvitationRepository>(
  (ref) => ApiInvitationRepository(ref.watch(api.coreApiProvider)),
);
