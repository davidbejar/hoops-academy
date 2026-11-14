import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../application/invitation_providers.dart';
import '../../domain/invitation_request.dart';
import '../landing_theme.dart';
import '../widgets/reveal.dart';

/// The invitation request form: validated here, then sent to
/// `POST /platform/academy-requests` (WP90, ADR-0044); the super admin decides.
class JoinSection extends StatelessWidget {
  const JoinSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l.landingJoinTitle, style: LandingType.title(w, p.text)),
        ),
        const SizedBox(height: 20),
        Text(l.landingJoinIntro, style: LandingType.lead(w, p.muted)),
      ],
    );
    return LandingFrame(
      child: Reveal(
        child: w.isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: intro,
                    ),
                  ),
                  const SizedBox(width: 72),
                  const Expanded(flex: 6, child: InvitationForm()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [intro, const SizedBox(height: 36), InvitationForm()],
              ),
      ),
    );
  }
}

class InvitationForm extends ConsumerStatefulWidget {
  const InvitationForm({super.key});

  @override
  ConsumerState<InvitationForm> createState() => _InvitationFormState();
}

class _InvitationFormState extends ConsumerState<InvitationForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _academy = TextEditingController();

  /// The honeypot (ADR-0044): never shown, never focusable, empty for people.
  final _website = TextEditingController();
  InvitationRole? _role;
  bool _confirmed = false;
  bool _sending = false;
  bool _failed = false;

  /// The academy name the server reported as taken (the message stays until
  /// the name changes).
  String? _takenAcademy;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _email, _academy]) {
      c.addListener(_hideConfirmation);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _academy, _website]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hideConfirmation() {
    if ((_confirmed || _failed) && _anyInput) {
      setState(() {
        _confirmed = false;
        _failed = false;
      });
    }
  }

  bool get _anyInput =>
      _name.text.isNotEmpty ||
      _email.text.isNotEmpty ||
      _academy.text.isNotEmpty;

  InvitationRequest get _request => InvitationRequest(
    name: _name.text,
    email: _email.text,
    role: _role,
    academy: _academy.text,
    languageCode: Localizations.localeOf(context).languageCode,
    website: _website.text,
  );

  Future<void> _submit() async {
    if (_sending) return;
    _takenAcademy = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    final outcome = await ref.read(invitationRepositoryProvider).send(_request);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (outcome) {
      case InvitationOutcome.sent:
        for (final c in [_name, _email, _academy, _website]) {
          c.clear();
        }
        setState(() {
          _role = null;
          _confirmed = true;
        });
        _formKey.currentState!.reset();
      case InvitationOutcome.academyTaken:
        _takenAcademy = _academy.text.trim();
        _formKey.currentState!.validate();
      case InvitationOutcome.failed:
        setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    InputDecoration decoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: p.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LandingPalette.accent, width: 2),
      ),
    );
    const gap = SizedBox(height: 16);
    return Container(
      key: const Key('join-form'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: p.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 40)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('join-name'),
              controller: _name,
              decoration: decoration(l.landingJoinName),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
            ),
            gap,
            TextFormField(
              key: const Key('join-email'),
              controller: _email,
              decoration: decoration(l.landingJoinEmail),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (_) =>
                  _request.problems.contains(InvitationProblem.invalidEmail)
                  ? l.landingJoinEmailInvalid
                  : null,
            ),
            gap,
            DropdownButtonFormField<InvitationRole>(
              key: const Key('join-role'),
              decoration: decoration(l.landingJoinRole),
              borderRadius: BorderRadius.circular(14),
              isExpanded: true,
              items: [
                for (final role in InvitationRole.values)
                  DropdownMenuItem(
                    value: role,
                    child: Text(
                      _roleLabel(l, role),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              // Also called with null when the form is reset after a send.
              onChanged: (role) => setState(() {
                _role = role;
                if (role != null) _confirmed = false;
              }),
              validator: (_) =>
                  _request.problems.contains(InvitationProblem.missingRole)
                  ? l.landingJoinRoleMissing
                  : null,
            ),
            gap,
            TextFormField(
              key: const Key('join-academy'),
              controller: _academy,
              decoration: decoration(l.landingJoinAcademy),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.organizationName],
              onFieldSubmitted: (_) => _submit(),
              validator: (_) =>
                  _request.problems.contains(InvitationProblem.missingAcademy)
                  ? l.landingJoinAcademyMissing
                  : _takenAcademy != null &&
                        _takenAcademy == _academy.text.trim()
                  ? l.landingJoinAcademyTaken
                  : null,
            ),
            _Honeypot(controller: _website),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('join-submit'),
              style: landingPrimaryButton(context),
              onPressed: _sending ? null : _submit,
              child: Text(l.landingJoinSubmit),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _confirmed || _failed
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _Confirmation(
                        key: Key(_failed ? 'join-failed' : 'join-confirmation'),
                        text: _failed
                            ? l.landingJoinFailed
                            : l.landingJoinConfirmation,
                        failed: _failed,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  static String _roleLabel(AppLocalizations l, InvitationRole role) =>
      switch (role) {
        InvitationRole.admin => l.landingJoinRoleAdmin,
        InvitationRole.coach => l.landingJoinRoleCoach,
        InvitationRole.parent => l.landingJoinRoleParent,
      };
}

/// The answer under the button: the confirmation, or why nothing was sent.
class _Confirmation extends StatelessWidget {
  const _Confirmation({super.key, required this.text, this.failed = false});

  final String text;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final p = LandingPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              failed ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: LandingPalette.accent,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: LandingType.body(p.text))),
          ],
        ),
      ),
    );
  }
}

/// A field for bots only: zero size, outside the semantics tree and the focus
/// order, so no person (or screen reader) ever reaches it.
class _Honeypot extends StatelessWidget {
  const _Honeypot({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ExcludeFocus(
      child: IgnorePointer(
        child: SizedBox(
          height: 0,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            maxWidth: 200,
            minHeight: 0,
            maxHeight: 60,
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: const Key('join-website'),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
