import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_providers.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../admin/application/admin_providers.dart' show membersProvider;
import '../../me/application/me_providers.dart';

/// Longest first or last name the contract takes.
const maxPersonNameLength = 80;

/// The member's own first and last name in the active academy (decision 73,
/// WP99), for every role: `PATCH /me` with the academy in the body.
///
/// The fields start from the given and family name `/me` reports for the
/// academy (core 3.6.0, decision 84); only the fields the member changed are
/// sent. A server that sends none leaves the fields empty.
class ProfileNameSection extends ConsumerStatefulWidget {
  const ProfileNameSection({
    super.key,
    required this.tenantId,
    required this.givenName,
    required this.familyName,
  });

  final String tenantId;
  final String? givenName;
  final String? familyName;

  @override
  ConsumerState<ProfileNameSection> createState() => _ProfileNameSectionState();
}

class _ProfileNameSectionState extends ConsumerState<ProfileNameSection> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _given;
  late final TextEditingController _family;
  late String _initialGiven;
  late String _initialFamily;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initialGiven = widget.givenName ?? '';
    _initialFamily = widget.familyName ?? '';
    _given = TextEditingController(text: _initialGiven);
    _family = TextEditingController(text: _initialFamily);
  }

  @override
  void didUpdateWidget(ProfileNameSection old) {
    super.didUpdateWidget(old);
    // The name changed elsewhere (a refresh of /me): start from it, unless
    // the member is typing.
    final renamed =
        old.givenName != widget.givenName ||
        old.familyName != widget.familyName;
    if (renamed && !_changed) {
      _initialGiven = widget.givenName ?? '';
      _initialFamily = widget.familyName ?? '';
      _given.text = _initialGiven;
      _family.text = _initialFamily;
    }
  }

  @override
  void dispose() {
    _given.dispose();
    _family.dispose();
    super.dispose();
  }

  bool get _changed =>
      _given.text.trim() != _initialGiven ||
      _family.text.trim() != _initialFamily;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final given = _given.text.trim();
    final family = _family.text.trim();
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final ok = await runAction(context, () async {
      await ref
          .read(meRepositoryProvider)
          .updateName(
            tenantId: widget.tenantId,
            givenName: given == _initialGiven ? null : given,
            familyName: family == _initialFamily ? null : family,
          );
      // The profile header and the academy's member list read it again.
      ref.invalidate(currentUserProvider);
      ref.invalidate(membersProvider);
    }, success: l.profileNameSaved);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _initialGiven = given;
        _initialFamily = family;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    final canSave = online && _changed && !_saving;

    InputDecoration decoration(String label) =>
        InputDecoration(labelText: label, counterText: '');
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l.fieldRequired : null;

    return SectionCard(
      key: const Key('profile-name'),
      title: l.profileNameTitle,
      subtitle: l.profileNameHint,
      child: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: HoopsSpace.gap,
          children: [
            TextFormField(
              key: const Key('profile-given-name'),
              controller: _given,
              maxLength: maxPersonNameLength,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              decoration: decoration(l.memberGivenName),
              validator: required,
            ),
            TextFormField(
              key: const Key('profile-family-name'),
              controller: _family,
              maxLength: maxPersonNameLength,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              decoration: decoration(l.memberFamilyName),
              validator: required,
            ),
            if (!online)
              Text(
                l.profileNameNeedsConnection,
                key: const Key('profile-name-offline'),
                style: Theme.of(context).textTheme.bodySmall!
                    .copyWith(color: HoopsTokens.colorsOf(context).inkMuted),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('profile-name-save'),
                onPressed: canSave ? _save : null,
                child: Text(l.profileNameSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
