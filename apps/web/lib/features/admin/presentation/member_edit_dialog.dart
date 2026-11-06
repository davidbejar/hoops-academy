import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/admin_providers.dart';
import 'members_screen.dart' show memberEmailPattern, memberErrorText;

/// Edits the personal data of a member (`UpdateMemberRequest`). E-mail, phone, birth date and gender can be emptied
/// (sent in `clear`). The server refuses to empty the e-mail of a member with a login (422 `LOGIN_REQUIRES_EMAIL`):
/// the dialog stays open and shows that message.
class MemberEditDialog extends ConsumerStatefulWidget {
  const MemberEditDialog({super.key, required this.member});
  final api.Member member;

  @override
  ConsumerState<MemberEditDialog> createState() => _MemberEditDialogState();
}

class _MemberEditDialogState extends ConsumerState<MemberEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _given = TextEditingController(text: widget.member.givenName);
  late final _family = TextEditingController(text: widget.member.familyName);
  late final _email = TextEditingController(text: widget.member.email ?? '');
  late final _phone = TextEditingController(text: widget.member.phone ?? '');
  late api.Date? _birth = widget.member.birthDate;
  late api.Gender? _gender = widget.member.gender;

  @override
  void dispose() {
    _given.dispose();
    _family.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  static String? _blankToNull(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.memberEdit,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => ref
            .read(membersProvider.notifier)
            .savePersonalData(
              widget.member.personId,
              givenName: _given.text.trim(),
              familyName: _family.text.trim(),
              email: _blankToNull(_email.text),
              phone: _blankToNull(_phone.text),
              birthDate: _birth,
              gender: _gender,
            ),
        success: l.saved,
        errorText: memberErrorText,
      ),
      children: [
        TextFormField(
          key: const Key('member-edit-given'),
          controller: _given,
          decoration: InputDecoration(labelText: l.memberGivenName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('member-edit-family'),
          controller: _family,
          decoration: InputDecoration(labelText: l.memberFamilyName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('member-edit-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l.memberEmail),
          validator: (v) =>
              (v ?? '').trim().isEmpty || memberEmailPattern.hasMatch(v!.trim())
              ? null
              : l.fieldInvalidEmail,
        ),
        formGap,
        TextFormField(
          key: const Key('member-edit-phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          maxLength: 32,
          decoration: InputDecoration(labelText: l.memberPhone),
        ),
        DateField(
          key: const Key('member-edit-birth'),
          label: l.playerBirthDate,
          value: _birth?.toDateTime(),
          lastDate: DateTime.now(),
          onChanged: (d) =>
              setState(() => _birth = api.Date(d.year, d.month, d.day)),
          onClear: () => setState(() => _birth = null),
        ),
        formGap,
        DropdownButtonFormField<api.Gender?>(
          key: const Key('member-edit-gender'),
          isExpanded: true,
          initialValue: _gender,
          decoration: InputDecoration(labelText: l.playerGender),
          items: [
            DropdownMenuItem<api.Gender?>(child: Text(l.memberGenderNone)),
            for (final g in [api.Gender.MALE, api.Gender.FEMALE])
              DropdownMenuItem<api.Gender?>(value: g, child: Text(g.label(l))),
          ],
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }
}
