import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';

import '../../../core/api/api.dart' as api;
import '../../me/application/me_providers.dart';
import '../../tenant/application/tenant_providers.dart';
import 'logo_revision.dart';
import '../data/academy_repository.dart';
import '../data/age_categories_repository.dart';
import '../data/members_repository.dart';
import '../data/seasons_repository.dart';

// ---------------------------------------------------------------- repositories

final academyRepositoryProvider = Provider<AcademyRepository>(
  (ref) => ApiAcademyRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);
final membersRepositoryProvider = Provider<MembersRepository>(
  (ref) => ApiMembersRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);
final seasonsRepositoryProvider = Provider<SeasonsRepository>(
  (ref) => ApiSeasonsRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);
final ageCategoriesRepositoryProvider = Provider<AgeCategoriesRepository>(
  (ref) => ApiAgeCategoriesRepository(
    ref.watch(api.coreApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);

// --------------------------------------------------------------------- academy

class AcademyData {
  const AcademyData({required this.profile, required this.settings});
  final api.TenantProfile profile;
  final api.TenantSettings settings;
}

/// A file chosen by the user (name + bytes), before validation.
class PickedFile {
  const PickedFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

/// Seam over the platform file chooser (replaced in tests).
final logoPickerProvider = Provider<Future<PickedFile?> Function()>(
  (ref) => () async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
      ],
    );
    if (file == null) return null;
    return PickedFile(name: file.name, bytes: await file.readAsBytes());
  },
);

class AcademyNotifier extends AsyncNotifier<AcademyData> {
  @override
  Future<AcademyData> build() async {
    final repo = ref.watch(academyRepositoryProvider);
    final results = await Future.wait([repo.profile(), repo.settings()]);
    return AcademyData(
      profile: results[0] as api.TenantProfile,
      settings: results[1] as api.TenantSettings,
    );
  }

  Future<void> save({
    required String name,
    required String timezone,
    required api.ApiLocale defaultLocale,
    required api.AgeRule ageRule,
    required int maxPlayUpLevels,
  }) async {
    final current = state.requireValue;
    final profile = await ref
        .read(academyRepositoryProvider)
        .save(
          profile: api.UpdateTenantProfileRequest(
            (b) => b
              ..name = name
              ..timezone = timezone
              ..defaultLocale = defaultLocale,
          ),
          settings: current.settings.rebuild(
            (b) => b
              ..ageRule = ageRule
              ..maxPlayUpLevels = maxPlayUpLevels,
          ),
        );
    state = AsyncData(
      AcademyData(
        profile: profile,
        settings: current.settings.rebuild(
          (b) => b
            ..ageRule = ageRule
            ..maxPlayUpLevels = maxPlayUpLevels,
        ),
      ),
    );
    ref.invalidate(tenantProfileProvider);
    ref.invalidate(currentUserProvider); // app bar shows the academy name
  }

  /// Uploads [file] (already validated) and refreshes every logo consumer.
  Future<void> uploadLogo(PickedFile file, String mimeType) async {
    await ref
        .read(academyRepositoryProvider)
        .uploadLogo(bytes: file.bytes, mimeType: mimeType, fileName: file.name);
    await _logoChanged();
  }

  Future<void> removeLogo() async {
    await ref.read(academyRepositoryProvider).deleteLogo();
    await _logoChanged();
  }

  Future<void> _logoChanged() async {
    ref.read(logoRevisionProvider.notifier).bump();
    ref.invalidate(tenantLogoProvider);
    ref.invalidate(tenantProfileProvider);
    ref.invalidate(currentUserProvider); // membership.hasLogo
    ref.invalidateSelf();
    await future;
  }
}

final academyProvider = AsyncNotifierProvider<AcademyNotifier, AcademyData>(
  AcademyNotifier.new,
);

// --------------------------------------------------------------------- members

class MemberQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final memberQueryProvider = NotifierProvider<MemberQuery, String>(
  MemberQuery.new,
);

class MembersNotifier extends AsyncNotifier<List<api.Member>> {
  @override
  Future<List<api.Member>> build() {
    final query = ref.watch(memberQueryProvider);
    return ref.watch(membersRepositoryProvider).list(query: query);
  }

  MembersRepository get _repo => ref.read(membersRepositoryProvider);

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  /// Returns the member with the temporary password of a login this call created. The caller shows it once and drops
  /// it; the state only ever holds the password-free list.
  Future<api.MemberWithPassword> invite({
    required String givenName,
    required String familyName,
    required String email,
    required Set<api.TenantRole> roles,
  }) async {
    final invited = await _repo.invite(
      api.InviteMemberRequest(
        (b) => b
          ..givenName = givenName
          ..familyName = familyName
          ..email = email
          ..roles.replace(roles)
          ..sendInvitation = true,
      ),
    );
    await _reload();
    return invited;
  }

  /// New temporary password for a pending member (returned once, see [invite]).
  Future<api.MemberWithPassword> issueTemporaryPassword(String personId) async {
    final member = await _repo.issueTemporaryPassword(personId);
    await _reload();
    return member;
  }

  Future<void> replaceRoles(String personId, Set<api.TenantRole> roles) async {
    await _repo.replaceRoles(personId, roles);
    await _reload();
  }

  Future<void> deactivate(String personId) async {
    await _repo.deactivate(personId);
    await _reload();
  }
}

final membersProvider =
    AsyncNotifierProvider<MembersNotifier, List<api.Member>>(
      MembersNotifier.new,
    );

/// Guardian links of one guardian (PARENT member), with add / remove.
class GuardianLinksNotifier extends AsyncNotifier<List<api.GuardianLink>> {
  GuardianLinksNotifier(this.guardianPersonId);
  final String guardianPersonId;

  @override
  Future<List<api.GuardianLink>> build() => ref
      .watch(membersRepositoryProvider)
      .guardianLinks(guardianPersonId: guardianPersonId);

  Future<void> add(String playerId) async {
    await ref
        .read(membersRepositoryProvider)
        .addGuardianLink(
          guardianPersonId: guardianPersonId,
          playerId: playerId,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String linkId) async {
    await ref.read(membersRepositoryProvider).removeGuardianLink(linkId);
    ref.invalidateSelf();
    await future;
  }
}

final guardianLinksProvider =
    AsyncNotifierProvider.family<
      GuardianLinksNotifier,
      List<api.GuardianLink>,
      String
    >(GuardianLinksNotifier.new);

// --------------------------------------------------------------------- seasons

class SeasonsNotifier extends AsyncNotifier<List<api.Season>> {
  @override
  Future<List<api.Season>> build() =>
      ref.watch(seasonsRepositoryProvider).list();

  SeasonsRepository get _repo => ref.read(seasonsRepositoryProvider);

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> create({
    required String name,
    required api.Date startsOn,
    required api.Date endsOn,
    required int referenceYear,
  }) async {
    await _repo.create(
      name: name,
      startsOn: startsOn,
      endsOn: endsOn,
      referenceYear: referenceYear,
    );
    await _reload();
  }

  Future<void> edit(
    String id, {
    required String name,
    required api.Date startsOn,
    required api.Date endsOn,
    required int referenceYear,
  }) async {
    await _repo.update(
      id,
      name: name,
      startsOn: startsOn,
      endsOn: endsOn,
      referenceYear: referenceYear,
    );
    await _reload();
  }

  /// Runs the rollover and returns its result (orphans, opened cases).
  Future<api.SeasonRolloverResult> rollover(
    String fromSeasonId, {
    bool cloneStaff = true,
    bool clonePlayers = true,
  }) async {
    final result = await _repo.rollover(
      fromSeasonId,
      cloneStaff: cloneStaff,
      clonePlayers: clonePlayers,
    );
    await _reload();
    return result;
  }
}

final seasonsProvider =
    AsyncNotifierProvider<SeasonsNotifier, List<api.Season>>(
      SeasonsNotifier.new,
    );

// ------------------------------------------------------------- age categories

class AgeCategoriesNotifier extends AsyncNotifier<List<api.AgeCategory>> {
  @override
  Future<List<api.AgeCategory>> build() async {
    final list = await ref.watch(ageCategoriesRepositoryProvider).list();
    return [...list]..sort((a, b) => a.rank.compareTo(b.rank));
  }

  AgeCategoriesRepository get _repo =>
      ref.read(ageCategoriesRepositoryProvider);

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> save({
    String? id,
    required String code,
    required String name,
    int? maxAge,
    required int rank,
  }) async {
    if (id == null) {
      await _repo.create(code: code, name: name, maxAge: maxAge, rank: rank);
    } else {
      await _repo.update(
        id,
        code: code,
        name: name,
        maxAge: maxAge,
        rank: rank,
      );
    }
    await _reload();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await _reload();
  }
}

final ageCategoriesProvider =
    AsyncNotifierProvider<AgeCategoriesNotifier, List<api.AgeCategory>>(
      AgeCategoriesNotifier.new,
    );
