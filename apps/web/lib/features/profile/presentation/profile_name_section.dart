import 'package:flutter/material.dart';
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
/// `/me` only carries the display name, so the fields start from it split at
/// the first space; only the fields the member changed are sent, so a wrong
/// split can never overwrite the other part.
class ProfileNameSection extends ConsumerStatefulWidget {
  const ProfileNameSection({
    super.key,
    required this.tenantId,
    required this.displayName,
  });

  final String tenantId;
  final String displayName;

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
    final (given, family) = splitDisplayName(widget.displayName);
    _initialGiven = given;
    _initialFamily = family;
    _given = TextEditingController(text: _initialGiven);
    _family = TextEditingController(text: _initialFamily);
  }

  @override
  void didUpdateWidget(ProfileNameSection old) {
    super.didUpdateWidget(old);
    // The name changed elsewhere (a refresh of /me): start from it, unless
    // the member is typing.
    if (old.displayName != widget.displayName && !_changed) {
      final (given, family) = splitDisplayName(widget.displayName);
      _initialGiven = given;
      _initialFamily = family;
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

/// A display name as first word and the rest.
(String, String) splitDisplayName(String displayName) {
  final name = displayName.trim();
  final space = name.indexOf(' ');
  return space < 0
      ? (name, '')
      : (name.substring(0, space), name.substring(space + 1).trim());
}
