# ADR-0067: Web helpers have one home: dates, form validators, error words, section states, exports

- Status: Accepted
- Date: 2026-11-24
- Records: decision 104 of 2026-11-23 (audit findings WEB-04..WEB-17 except WEB-02 and WEB-13)
- Related: ADR-0030, ADR-0032, ADR-0040 (widget kit), ADR-0042, ADR-0061,
  [WP135](../wp/WP135-web-shared-dates-validators-states.md)

## Context
Below the widget kit, small helpers were written where they were needed: ten date formatters (and a dead pair), five
e-mail patterns, eight decimal parses and three ways to write the same measurement (the growth chart showed 37.55 as
37.5 while the list showed 37.55), five per-feature mappers from error code to message (30 `errorText:` arguments),
seven section-sized loading / error / empty variants, two near-copies of the server export button, and 18 identical
`_reload` helpers in the notifiers.

## Decision
1. **Dates** live in `core/time/dates.dart` (pure Dart): ISO text, `dd/MM`, `dd/MM/yyyy`, `dd/MM/yy` of the charts,
   the locale's `yMMMd`, and `toApiDate` / `toAthDate` / `toFinDate`, one per generated client. What the user reads
   per screen did not change.
2. **Form helpers** live in `core/ui/validators.dart`, exported by the kit: `requiredValidator`, `emailValidator`,
   `optionalEmailValidator`, `decimalValidator`, `optionalDecimalValidator`, `parseDecimal`, `blankToNull`, and
   `formatMeasure` (a whole number without decimals, otherwise at most two without trailing zero) for every place a
   measurement is written.
3. **Error words** are one table in `AppError.message` (`app_error_view.dart`): every business code of the services
   and a 501 ("not available yet"). A screen passes `errorText` only where its context needs other words for a
   code; members do for `EMAIL_TAKEN` and `INVITATION_NOT_PENDING` (`memberErrorText`), and fall back to the table.
   `AppErrorText` is gone.
4. **Section states.** `AsyncSection` (`core/ui/async_body.dart`) is the loading / error (mapped message, optional
   label, retry) / empty state of a block inside a page or a card; `AsyncBody` stays for whole pages.
5. **Server exports.** `ServerExportButton.csv` / `.pdf` is the one button for a file the server builds, with one
   handling of `EXPORT_TOO_LARGE` (the screen's message or the narrow-the-request text) and 503. `BusyIconButton` is
   shared with `ExportMenu`.
6. **Notifiers** reload through the `Reloading` mixin (`core/state/reloading.dart`).
7. **Provider lifetime.** A provider family keyed by one id that a detail screen reads is `autoDispose`
   (`provider_lifetime_test.dart`); `auditQueryProvider` (the filter) and `playerNameProvider` (a derived lookup)
   stay as they are.

## Consequences
A new code is worded once; a change of an e-mail rule, a date style or the export UX is one edit. Tests have
`pumpAsSuperAdmin` and `localizedApp` for the two set-ups that were copied. Unworded 409s keep the generic text, so
a test that wants an unworded code must use an unknown one.
