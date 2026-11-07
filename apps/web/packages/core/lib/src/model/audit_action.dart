//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_action.g.dart';

/// An administrative action of the audit trail. One source: core's `AuditAction` (a test keeps them equal); each action, its target type and its metadata keys are listed in `docs/domain/audit-events.md`.
class AuditAction extends EnumClass {
  @BuiltValueEnumConst(wireName: r'admin.added')
  static const AuditAction adminPeriodAdded = _$adminPeriodAdded;
  @BuiltValueEnumConst(wireName: r'admin.removed')
  static const AuditAction adminPeriodRemoved = _$adminPeriodRemoved;
  @BuiltValueEnumConst(wireName: r'admin.temporary_password_issued')
  static const AuditAction adminPeriodTemporaryPasswordIssued =
      _$adminPeriodTemporaryPasswordIssued;
  @BuiltValueEnumConst(wireName: r'admin.updated')
  static const AuditAction adminPeriodUpdated = _$adminPeriodUpdated;
  @BuiltValueEnumConst(wireName: r'approval.cancelled')
  static const AuditAction approvalPeriodCancelled = _$approvalPeriodCancelled;
  @BuiltValueEnumConst(wireName: r'guardian_link.created')
  static const AuditAction guardianLinkPeriodCreated =
      _$guardianLinkPeriodCreated;
  @BuiltValueEnumConst(wireName: r'guardian_link.removed')
  static const AuditAction guardianLinkPeriodRemoved =
      _$guardianLinkPeriodRemoved;
  @BuiltValueEnumConst(wireName: r'member.deactivated')
  static const AuditAction memberPeriodDeactivated = _$memberPeriodDeactivated;
  @BuiltValueEnumConst(wireName: r'member.invitation_accepted')
  static const AuditAction memberPeriodInvitationAccepted =
      _$memberPeriodInvitationAccepted;
  @BuiltValueEnumConst(wireName: r'member.invited')
  static const AuditAction memberPeriodInvited = _$memberPeriodInvited;
  @BuiltValueEnumConst(wireName: r'member.login_email_changed')
  static const AuditAction memberPeriodLoginEmailChanged =
      _$memberPeriodLoginEmailChanged;
  @BuiltValueEnumConst(wireName: r'member.roles_replaced')
  static const AuditAction memberPeriodRolesReplaced =
      _$memberPeriodRolesReplaced;
  @BuiltValueEnumConst(wireName: r'member.temporary_password_expired')
  static const AuditAction memberPeriodTemporaryPasswordExpired =
      _$memberPeriodTemporaryPasswordExpired;
  @BuiltValueEnumConst(wireName: r'member.temporary_password_issued')
  static const AuditAction memberPeriodTemporaryPasswordIssued =
      _$memberPeriodTemporaryPasswordIssued;
  @BuiltValueEnumConst(wireName: r'member.updated')
  static const AuditAction memberPeriodUpdated = _$memberPeriodUpdated;
  @BuiltValueEnumConst(wireName: r'player.approved')
  static const AuditAction playerPeriodApproved = _$playerPeriodApproved;
  @BuiltValueEnumConst(wireName: r'player.rejected')
  static const AuditAction playerPeriodRejected = _$playerPeriodRejected;
  @BuiltValueEnumConst(wireName: r'player.requested')
  static const AuditAction playerPeriodRequested = _$playerPeriodRequested;
  @BuiltValueEnumConst(wireName: r'player.withdrawn')
  static const AuditAction playerPeriodWithdrawn = _$playerPeriodWithdrawn;
  @BuiltValueEnumConst(wireName: r'tenant.created')
  static const AuditAction tenantPeriodCreated = _$tenantPeriodCreated;
  @BuiltValueEnumConst(wireName: r'tenant.events_backfilled')
  static const AuditAction tenantPeriodEventsBackfilled =
      _$tenantPeriodEventsBackfilled;
  @BuiltValueEnumConst(wireName: r'tenant.logo_removed')
  static const AuditAction tenantPeriodLogoRemoved = _$tenantPeriodLogoRemoved;
  @BuiltValueEnumConst(wireName: r'tenant.logo_replaced')
  static const AuditAction tenantPeriodLogoReplaced =
      _$tenantPeriodLogoReplaced;
  @BuiltValueEnumConst(wireName: r'tenant.master_data_changed')
  static const AuditAction tenantPeriodMasterDataChanged =
      _$tenantPeriodMasterDataChanged;
  @BuiltValueEnumConst(wireName: r'tenant.profile_changed')
  static const AuditAction tenantPeriodProfileChanged =
      _$tenantPeriodProfileChanged;
  @BuiltValueEnumConst(wireName: r'tenant.reactivated')
  static const AuditAction tenantPeriodReactivated = _$tenantPeriodReactivated;
  @BuiltValueEnumConst(wireName: r'tenant.settings_changed')
  static const AuditAction tenantPeriodSettingsChanged =
      _$tenantPeriodSettingsChanged;
  @BuiltValueEnumConst(wireName: r'tenant.suspended')
  static const AuditAction tenantPeriodSuspended = _$tenantPeriodSuspended;
  @BuiltValueEnumConst(wireName: r'tenant.withdrawn')
  static const AuditAction tenantPeriodWithdrawn = _$tenantPeriodWithdrawn;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AuditAction unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<AuditAction> get serializer => _$auditActionSerializer;

  const AuditAction._(String name) : super(name);

  static BuiltSet<AuditAction> get values => _$values;
  static AuditAction valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AuditActionMixin = Object with _$AuditActionMixin;
