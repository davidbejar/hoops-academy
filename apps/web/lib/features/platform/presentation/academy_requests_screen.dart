import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/temporary_password_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/academy_request_providers.dart';
import '../application/platform_providers.dart';
import '../domain/acceptance_defaults.dart';

/// The super admin's workbench of academy requests (WP90, ADR-0044): pending, accepted and rejected; accept creates
/// the academy with the requester as its first administrator, reject e-mails a reason.
class AcademyRequestsScreen extends ConsumerWidget {
  const AcademyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tab = ref.watch(academyRequestTabProvider);
    return Guarded(
      allowed: ref.watch(isSuperAdminProvider),
      child: Scaffold(
        body: Column(
          children: [
            ContentFrame(
              maxWidth: WidthClass.readingMax,
              child: Padding(
                padding: const EdgeInsets.only(top: HoopsSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: HoopsSpace.gap,
                  children: [
                    PageHeader(title: l.academyRequestsTitle),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: HoopsSpace.sm,
                        children: [
                          for (final s in _statuses)
                            ChoiceChip(
                              key: Key('requests-${s.name}'),
                              label: Text(s.label(l)),
                              selected: tab == s,
                              onSelected: (_) => ref
                                  .read(academyRequestTabProvider.notifier)
                                  .set(s),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AsyncBody<List<api.AcademyRequest>>(
                value: ref.watch(academyRequestsProvider(tab)),
                onRetry: () => ref.invalidate(academyRequestsProvider(tab)),
                isEmpty: (d) => d.isEmpty,
                emptyMessage: l.academyRequestsEmpty,
                builder: (context, data) => PageBody(
                  children: [
                    Column(
                      spacing: HoopsSpace.gap,
                      children: [for (final r in data) _RequestCard(r)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _statuses = [
  api.AcademyRequestStatus.PENDING,
  api.AcademyRequestStatus.ACCEPTED,
  api.AcademyRequestStatus.REJECTED,
];

extension AcademyRequestStatusLabel on api.AcademyRequestStatus {
  String label(AppLocalizations l) => switch (this) {
    api.AcademyRequestStatus.PENDING => l.academyRequestStatusPending,
    api.AcademyRequestStatus.ACCEPTED => l.academyRequestStatusAccepted,
    _ => l.academyRequestStatusRejected,
  };
}

extension AcademyRequestRoleLabel on api.AcademyRequestRole {
  String label(AppLocalizations l) => switch (this) {
    api.AcademyRequestRole.ADMIN => l.landingJoinRoleAdmin,
    api.AcademyRequestRole.COACH => l.landingJoinRoleCoach,
    _ => l.landingJoinRoleParent,
  };
}

/// Localised text for a failed decision, by the server's error code (never its English detail).
String academyRequestErrorText(Object error, AppLocalizations l) {
  final e = AppError.of(error);
  return switch (e.code) {
    'REQUEST_NOT_PENDING' => l.academyRequestErrorNotPending,
    'ACADEMY_NAME_TAKEN' => l.academyRequestErrorNameTaken,
    'SLUG_TAKEN' => l.academyRequestErrorSlugTaken,
    'IDENTITY_PROVIDER_UNAVAILABLE' => l.adminErrorIdentityProvider,
    _ => e.message(l),
  };
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard(this.request);
  final api.AcademyRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final requested = DateFormat.yMMMd(locale)
        .format(request.requestedAt.toLocal());
    final who = [
      if ((request.name ?? '').isNotEmpty) request.name!,
      request.email,
    ].join(' · ');
    final pending = request.status == api.AcademyRequestStatus.PENDING;
    final mailMissing = !pending && request.notifiedAt == null;
    return SectionCard(
      key: Key('request-${request.id}'),
      title: request.academyName,
      subtitle: who,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.sm,
        children: [
          Wrap(
            spacing: HoopsSpace.sm,
            runSpacing: HoopsSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(
                request.role.label(l),
                tone: HoopsTone.neutral,
                icon: Icons.badge_outlined,
              ),
              Text(
                l.academyRequestRequestedOn(requested),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (mailMissing)
                StatusChip(
                  l.academyRequestMailNotSent,
                  key: Key('request-mail-missing-${request.id}'),
                  tone: HoopsTone.warning,
                  icon: Icons.mark_email_unread_outlined,
                ),
            ],
          ),
          if (request.reason != null)
            Text(
              '${l.academyRequestReasonShown}: ${request.reason}',
              key: Key('request-reason-${request.id}'),
            ),
          if (pending)
            Wrap(
              spacing: HoopsSpace.sm,
              runSpacing: HoopsSpace.sm,
              children: [
                FilledButton.icon(
                  key: Key('request-accept-${request.id}'),
                  icon: const Icon(Icons.check),
                  label: Text(l.academyRequestAccept),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => AcceptRequestDialog(request: request),
                  ),
                ),
                OutlinedButton.icon(
                  key: Key('request-reject-${request.id}'),
                  icon: const Icon(Icons.close),
                  label: Text(l.academyRequestReject),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => RejectRequestDialog(request: request),
                  ),
                ),
              ],
            ),
          if (request.tenantId != null)
            TextButton.icon(
              key: Key('request-open-${request.id}'),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.academyRequestOpenAcademy),
              onPressed: () =>
                  context.go('/app-admin/academies/${request.tenantId}'),
            ),
        ],
      ),
    );
  }
}

final _slugPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$');

/// Accept = the "new academy" form pre-filled from the request; the academy name and the e-mail are the request's.
class AcceptRequestDialog extends ConsumerStatefulWidget {
  const AcceptRequestDialog({super.key, required this.request});
  final api.AcademyRequest request;

  @override
  ConsumerState<AcceptRequestDialog> createState() =>
      _AcceptRequestDialogState();
}

class _AcceptRequestDialogState extends ConsumerState<AcceptRequestDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _slug;
  final _timezone = TextEditingController(text: 'Europe/Madrid');
  late final TextEditingController _given;
  late final TextEditingController _family;
  late api.ApiLocale _locale;

  /// Shown once the form has closed (see [FormDialog.afterClose]); never kept past that.
  Future<void> Function()? _announce;

  @override
  void initState() {
    super.initState();
    final (given, family) = splitName(widget.request.name);
    _slug = TextEditingController(
      text: suggestSlug(widget.request.academyName),
    );
    _given = TextEditingController(text: given);
    _family = TextEditingController(text: family);
    _locale = widget.request.locale;
  }

  @override
  void dispose() {
    for (final c in [_slug, _timezone, _given, _family]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _submit() async {
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context, rootNavigator: true).context;
    final (given, family) = (_given.text.trim(), _family.text.trim());
    api.AcademyRequestAccepted? accepted;
    final ok = await runAction(
      context,
      () async => accepted = await ref
          .read(academyRequestsProvider(widget.request.status).notifier)
          .accept(
            widget.request.id,
            api.AcceptAcademyRequest(
              (b) => b
                ..slug = _slug.text.trim()
                ..timezone = _timezone.text.trim()
                ..defaultLocale = _locale
                ..firstAdmin.replace(
                  api.AcceptedAdmin(
                    (a) => a
                      ..givenName = given
                      ..familyName = family
                      ..locale = widget.request.locale,
                  ),
                ),
            ),
          ),
      errorText: academyRequestErrorText,
    );
    if (ok) {
      _announce = () => announceLogin(
        nav,
        person: '$given $family',
        email: widget.request.email,
        temporaryPassword: accepted?.temporaryPassword,
        done: l.tenantCreated,
      );
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget field(
      String key,
      TextEditingController c,
      String label, {
      String? Function(String?)? validator,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: HoopsSpace.gap),
      child: TextFormField(
        key: Key(key),
        controller: c,
        decoration: InputDecoration(labelText: label),
        validator: validator ?? (v) => requiredValidator(l, v),
      ),
    );
    Widget fixed(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: HoopsSpace.gap),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value),
      ),
    );
    return FormDialog(
      title: l.academyRequestAcceptTitle,
      formKey: _form,
      onSubmit: _submit,
      submitLabel: l.academyRequestAccept,
      afterClose: () async => _announce?.call(),
      children: [
        NoticeBanner(
          message: l.academyRequestAcceptNote,
          tone: HoopsTone.info,
          icon: Icons.info_outline,
        ),
        formGap,
        fixed(l.tenantName, widget.request.academyName),
        field(
          'accept-slug',
          _slug,
          l.tenantSlug,
          validator: (v) => _slugPattern.hasMatch((v ?? '').trim())
              ? null
              : l.tenantSlugInvalid,
        ),
        field('accept-timezone', _timezone, l.tenantTimezone),
        DropdownButtonFormField<api.ApiLocale>(
          key: const Key('accept-locale'),
          initialValue: _locale,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.tenantLocale),
          items: [
            DropdownMenuItem(
              value: api.ApiLocale.es,
              child: Text(l.languageName_es),
            ),
            DropdownMenuItem(
              value: api.ApiLocale.en,
              child: Text(l.languageName_en),
            ),
            DropdownMenuItem(
              value: api.ApiLocale.id,
              child: Text(l.languageName_id),
            ),
          ],
          onChanged: (v) => setState(() => _locale = v ?? _locale),
        ),
        formGap,
        fixed(l.tenantAdminEmail, widget.request.email),
        field('accept-given', _given, l.tenantAdminGivenName),
        field('accept-family', _family, l.tenantAdminFamilyName),
      ],
    );
  }
}

/// Reject with a reason, which is e-mailed to the requester in the language of their request.
class RejectRequestDialog extends ConsumerStatefulWidget {
  const RejectRequestDialog({super.key, required this.request});
  final api.AcademyRequest request;

  @override
  ConsumerState<RejectRequestDialog> createState() =>
      _RejectRequestDialogState();
}

class _RejectRequestDialogState extends ConsumerState<RejectRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<bool> _submit() {
    final l = AppLocalizations.of(context);
    return runAction(
      context,
      () => ref
          .read(academyRequestsProvider(widget.request.status).notifier)
          .reject(widget.request.id, _reason.text.trim()),
      success: l.academyRequestRejected,
      errorText: academyRequestErrorText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.academyRequestRejectTitle,
      formKey: _form,
      onSubmit: _submit,
      submitLabel: l.academyRequestReject,
      children: [
        Text(widget.request.academyName),
        formGap,
        TextFormField(
          key: const Key('reject-reason'),
          controller: _reason,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          decoration: InputDecoration(labelText: l.academyRequestReason),
          validator: (v) => requiredValidator(l, v),
        ),
      ],
    );
  }
}
