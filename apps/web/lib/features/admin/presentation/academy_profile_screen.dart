import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tenant/application/tenant_providers.dart';
import '../application/admin_providers.dart';
import '../domain/logo_validation.dart';
import 'members_screen.dart' show memberEmailPattern;

String logoProblemMessage(LogoProblem problem, AppLocalizations l) =>
    switch (problem) {
      LogoProblem.tooLarge => l.logoErrorTooLarge,
      LogoProblem.wrongType => l.logoErrorWrongType,
      LogoProblem.empty => l.logoErrorEmpty,
    };

class AcademyProfileScreen extends ConsumerWidget {
  const AcademyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final academy = ref.watch(academyProvider);
    return SubPage(
      title: l.adminAcademyProfile,
      parentPath: '/admin',
      child: AsyncBody<AcademyData>(
        value: academy,
        onRetry: () => ref.invalidate(academyProvider),
        builder: (context, data) => PageBody(
          header: PageHeader(title: l.adminAcademyProfile),
          children: [
            SectionCard(title: l.logoTitle, child: const LogoSection()),
            SectionCard(child: _ProfileForm(data: data)),
          ],
        ),
      ),
    );
  }
}

/// Logo preview + choose / upload / remove with client-side checks.
class LogoSection extends ConsumerStatefulWidget {
  const LogoSection({super.key});

  @override
  ConsumerState<LogoSection> createState() => _LogoSectionState();
}

class _LogoSectionState extends ConsumerState<LogoSection> {
  PickedFile? _picked;
  String? _mime;
  LogoProblem? _problem;
  bool _busy = false;

  Future<void> _choose() async {
    final file = await ref.read(logoPickerProvider)();
    if (file == null || !mounted) return;
    final check = validateLogo(fileName: file.name, bytes: file.bytes);
    setState(() {
      _problem = check.problem;
      _picked = check.isValid ? file : null;
      _mime = check.mimeType;
    });
  }

  Future<void> _upload() async {
    final file = _picked!;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(academyProvider.notifier).uploadLogo(file, _mime!),
      success: AppLocalizations.of(context).logoUploaded,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _picked = null;
    });
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    if (!await confirmDialog(context, message: l.logoRemoveConfirm)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    await runAction(
      context,
      () => ref.read(academyProvider.notifier).removeLogo(),
      success: l.logoRemoved,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasLogo = ref.watch(academyProvider).value?.profile.hasLogo ?? false;
    final current = ref.watch(tenantLogoProvider).value;
    final shown = _picked?.bytes ?? (hasLogo ? current : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              key: const Key('logo-preview'),
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HoopsTokens.colorsOf(context).surfaceMuted,
                borderRadius: BorderRadius.circular(HoopsRadius.md),
              ),
              child: shown == null
                  ? Text(
                      l.logoNone,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(HoopsRadius.md),
                      child: Image.memory(
                        shown,
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            const SizedBox(width: HoopsSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _picked != null ? l.logoPreview : l.logoHint,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: HoopsSpace.sm),
                  Wrap(
                    spacing: HoopsSpace.sm,
                    runSpacing: HoopsSpace.sm,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('logo-choose'),
                        onPressed: _busy ? null : _choose,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(l.logoChoose),
                      ),
                      if (_picked != null)
                        FilledButton.icon(
                          key: const Key('logo-upload'),
                          onPressed: _busy ? null : _upload,
                          icon: const Icon(Icons.upload),
                          label: Text(l.logoUpload),
                        ),
                      if (hasLogo && _picked == null)
                        TextButton.icon(
                          key: const Key('logo-remove'),
                          onPressed: _busy ? null : _remove,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l.logoRemove),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_problem != null) ...[
          const SizedBox(height: HoopsSpace.sm),
          Text(
            logoProblemMessage(_problem!, l),
            key: const Key('logo-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: HoopsTokens.colorsOf(context)
                  .tone(HoopsTone.danger)
                  .foreground,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.data});
  final AcademyData data;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.data.profile.name);
  late final _timezone = TextEditingController(
    text: widget.data.profile.timezone,
  );
  late final _maxPlayUp = TextEditingController(
    text: (widget.data.settings.maxPlayUpLevels ?? 0).toString(),
  );
  late final _contactEmail = TextEditingController(
    text: widget.data.profile.contactEmail ?? '',
  );
  late final _website = TextEditingController(
    text: widget.data.profile.websiteUrl ?? '',
  );
  late api.AgeRule _ageRule = widget.data.settings.ageRule;
  late api.ApiLocale _locale = widget.data.profile.defaultLocale;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _timezone.dispose();
    _maxPlayUp.dispose();
    _contactEmail.dispose();
    _website.dispose();
    super.dispose();
  }

  static String? _blankToNull(String v) => v.trim().isEmpty ? null : v.trim();

  static bool _isWebAddress(String v) {
    final uri = Uri.tryParse(v);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    await runAction(
      context,
      () => ref
          .read(academyProvider.notifier)
          .save(
            name: _name.text.trim(),
            timezone: _timezone.text.trim(),
            defaultLocale: _locale,
            ageRule: _ageRule,
            maxPlayUpLevels: int.parse(_maxPlayUp.text.trim()),
            contactEmail: _blankToNull(_contactEmail.text),
            websiteUrl: _blankToNull(_website.text),
          ),
      success: l.saved,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('academy-name'),
            controller: _name,
            decoration: InputDecoration(labelText: l.academyName),
            validator: (v) => requiredValidator(l, v),
          ),
          const SizedBox(height: HoopsSpace.md),
          TextFormField(
            key: const Key('academy-timezone'),
            controller: _timezone,
            decoration: InputDecoration(labelText: l.academyTimezone),
            validator: (v) => requiredValidator(l, v),
          ),
          const SizedBox(height: HoopsSpace.md),
          DropdownButtonFormField<api.AgeRule>(
            isExpanded: true,
            key: const Key('academy-age-rule'),
            initialValue: _ageRule,
            decoration: InputDecoration(labelText: l.academyAgeRule),
            items: [
              for (final r in [api.AgeRule.BIRTH_YEAR, api.AgeRule.BIRTHDAY])
                DropdownMenuItem(value: r, child: Text(r.label(l))),
            ],
            onChanged: (v) => setState(() => _ageRule = v ?? _ageRule),
          ),
          const SizedBox(height: HoopsSpace.md),
          TextFormField(
            key: const Key('academy-max-play-up'),
            controller: _maxPlayUp,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.academyMaxPlayUp),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              return n == null || n < 0 || n > 5 ? l.fieldInvalidNumber : null;
            },
          ),
          const SizedBox(height: HoopsSpace.md),
          DropdownButtonFormField<api.ApiLocale>(
            isExpanded: true,
            key: const Key('academy-locale'),
            initialValue: _locale,
            decoration: InputDecoration(labelText: l.academyDefaultLocale),
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
          const SizedBox(height: HoopsSpace.md),
          TextFormField(
            key: const Key('academy-contact-email'),
            controller: _contactEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l.academyContactEmail),
            validator: (v) =>
                (v ?? '').trim().isEmpty ||
                    memberEmailPattern.hasMatch(v!.trim())
                ? null
                : l.fieldInvalidEmail,
          ),
          const SizedBox(height: HoopsSpace.md),
          TextFormField(
            key: const Key('academy-website'),
            controller: _website,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: l.academyWebsite),
            validator: (v) =>
                (v ?? '').trim().isEmpty || _isWebAddress(v!.trim())
                ? null
                : l.fieldInvalidUrl,
          ),
          const SizedBox(height: HoopsSpace.lg),
          FilledButton(
            key: const Key('academy-save'),
            onPressed: _busy ? null : _save,
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
