import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tenant/application/tenant_providers.dart';
import '../application/admin_providers.dart';
import '../domain/logo_validation.dart';

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
        builder: (context, data) => ListView(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          children: [
            const LogoSection(),
            const Divider(height: AppTokens.spaceXl),
            _ProfileForm(data: data),
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
        Text(l.logoTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTokens.spaceSm),
        Row(
          children: [
            Container(
              key: const Key('logo-preview'),
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: shown == null
                  ? Text(
                      l.logoNone,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      child: Image.memory(
                        shown,
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            const SizedBox(width: AppTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _picked != null ? l.logoPreview : l.logoHint,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  Wrap(
                    spacing: AppTokens.spaceSm,
                    runSpacing: AppTokens.spaceSm,
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
          const SizedBox(height: AppTokens.spaceSm),
          Text(
            logoProblemMessage(_problem!, l),
            key: const Key('logo-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
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
  late api.AgeRule _ageRule = widget.data.settings.ageRule;
  late api.ApiLocale _locale = widget.data.profile.defaultLocale;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _timezone.dispose();
    _maxPlayUp.dispose();
    super.dispose();
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
          const SizedBox(height: AppTokens.spaceMd),
          TextFormField(
            key: const Key('academy-timezone'),
            controller: _timezone,
            decoration: InputDecoration(labelText: l.academyTimezone),
            validator: (v) => requiredValidator(l, v),
          ),
          const SizedBox(height: AppTokens.spaceMd),
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
          const SizedBox(height: AppTokens.spaceMd),
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
          const SizedBox(height: AppTokens.spaceMd),
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
          const SizedBox(height: AppTokens.spaceLg),
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
