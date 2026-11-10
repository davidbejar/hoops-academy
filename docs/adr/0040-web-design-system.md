# ADR-0040: Web design system: landing-page tokens, a token-mapped Material 3 theme, a shared widget kit, AA proven by a test

- Status: Accepted (WP72, fifth round)
- Date: 2026-11-07
- Related: decision 52 of 2026-11-06 (the whole app takes the landing page's look), decision 57 (the landing PNGs are
  the reference and stay unchanged), WP70 (landing page, `features/landing`), WP73/74/75 (wave 2: feature screens),
  ADR-0004 (Flutter Web PWA), `apps/web/lib/core/design/**`, `apps/web/lib/app/theme.dart`, `apps/web/lib/core/ui/**`

## Context
The product owner judged the app "not attractive" and the landing page "very attractive". The app's theme was
`ColorScheme.fromSeed(#E8590C)`: Material 3 derived every role from the seed, which tinted every surface pink-peach,
and screens used `AppTokens` (a handful of spacing and radius constants) plus raw scheme roles. The landing page
(WP70) has its own palette: one basketball orange on a warm off-white (`#FAF7F2`) or near-black (`#0E0F11`) canvas,
white / graphite cards with hairline borders, heavy and slightly tight headings. Its white-on-orange buttons measure
3.58:1, below WCAG AA for normal text. Feature screens will be restyled by three agents in parallel (wave 2), so they
need one vocabulary, not three interpretations of a picture.

## Decision
1. **Tokens are a Dart API in `lib/core/design/`** (one import, `tokens.dart`): `HoopsColors` (a `ThemeExtension`,
   light and dark: canvas, surface, surfaceMuted, surfaceRaised, ink, inkMuted, border, borderStrong, accent /
   onAccent, accentText, accentSoft / onAccentSoft, inverse, the brand orange, and the tones neutral / success /
   warning / danger / info as `ToneColors(foreground, container, onContainer)`; the chart palette of WP14 is carried
   unchanged), `HoopsTone`, `HoopsSpace` (4 px grid, `gap` = 12), `HoopsRadius` (6 / 10 / 14 / 20 / 28 / pill),
   `HoopsElevation` (flat, raised, overlay: the design is flat with hairlines), `HoopsMotion` (120 / 200 / 320 / 700 ms),
   `HoopsSize`, `WidthClass` (compact < 720 ≤ medium < 1024 ≤ expanded; gutters 16 / 24 / 32) and `HoopsType` (type
   scale, eyebrow, stat value, brand line). Widgets use tokens, never literals; `HoopsTokens.colorsOf(context)` reads
   the colours. `AppTokens` stays as short aliases onto the new scale so the screens of earlier WPs compile unchanged.
2. **The theme maps every Material role to a token** (`hoopsColorScheme`, no seed), with component themes for app bar
   (canvas, bottom hairline, no scroll tint), navigation bar and rail (surface, soft-orange pill indicator, heavy
   selected label), cards (surface, hairline, radius 20, flat), chips, all button kinds (48 px, radius 14), FAB,
   segmented buttons, outlined inputs, dialogs, bottom sheets, menus, snack bars, tooltips, list tiles, tabs, data
   tables, dividers and progress indicators.
3. **Button contrast: a darker orange for fills, the brand orange for marks.** Filled buttons and the FAB use orange
   700 `#C2410C` with white labels (5.18:1) in light mode, and `#F2783A` with a near-black label (6.63:1) in dark
   mode. `#E8590C` stays the brand colour for icons, indicators, the tab underline and the rail's mark (3.35:1 on
   the canvas: fine for non-text, WCAG 1.4.11). Orange text uses `accentText` (`#B4380A`, 5.6:1 on the canvas).
4. **AA is proven by a test, not by review.** `test/core/design/contrast_test.dart` computes WCAG contrast
   (`contrastRatio`, alpha composited) over `HoopsColors.textPairs` (every text role on every surface it is used on,
   every tone's onContainer on its container: ≥ 4.5:1) and `controlPairs` (brand, accent and control outlines on the
   surfaces: ≥ 3:1), in light and dark, plus the theme's on-colour pairs. A new colour role must add its pairs there.
5. **A shared widget kit in `lib/core/ui/`** (one import, `kit.dart`): `PageHeader`, `PageBody`, `ContentFrame`,
   `SubPage` (kept API), `SectionCard`, `StatTile`, `EmptyState`, `StatusChip` (+ `InfoChip` / `ChipTone` kept as a
   mapping onto it), `ListRow` + `InitialsAvatar`, `ResponsiveGrid`, `NoticeBanner`, `showActionSheet` +
   `SheetAction`, `FormDialog` (kept API). `AppErrorView`, `EmptyView` and `ModulePlaceholder` render through
   `EmptyState`. Each kit widget has a widget test and a light and a dark golden (`test/golden/goldens/kit/`).
6. **The shell takes the look**: canvas app bar with the academy's logo / initials and name in the brand line, the
   person's initials as the profile button, notices as `NoticeBanner` (offline = warning, demo = accent, update =
   info), bottom bar on phones (surface with a top hairline), a rail with the basketball mark from 720 px that
   extends with labels from 1024 px. Routes, keys and behaviour are unchanged.
7. **Fonts stay the platform's Roboto** (bundled by the release build since F-09); no new font asset.

## How feature screens adopt it (wave 2)
Replace raw `ColorScheme` roles and literals with tokens; wrap pages in `PageBody` / `ContentFrame` + `PageHeader`
(or keep `SubPage` for sub-pages); lists of `Card(ListTile)` become `ListRow`; ad-hoc coloured `Container` labels
become `StatusChip` with a `HoopsTone` (role, availability, match state, injury); dashboards use `StatTile` in a
`ResponsiveGrid`; titled blocks use `SectionCard`; "nothing here" and error states use `EmptyState` (via
`AsyncBody` where it fits); action menus on phones use `showActionSheet`. The checklist with file-level hints is in
`apps/web/README.md` ("Design system") and in the WP72 handover.

## Consequences
- Every golden that renders the app theme was re-recorded once (listed in the WP72 handover); feature screens look
  closer to the landing already because they inherit the theme, before wave 2 touches them.
- The landing keeps its own `LandingPalette` (same values); a later clean-up can point it at `HoopsColors`.
- Positive statuses that used the orange container (`ChipTone.good`) are green now (success tone).
- A colour change is a token change plus a green contrast test; a failing pair names itself.

## Amendment (WP95)
`AppTokens`, `InfoChip` and `ChipTone` are deleted (nothing used them); `LandingPalette` reads `HoopsColors`.
`ContentFrame` stretches a narrower section to the column; `SectionCard` provides a transparent `Material`;
`AsyncBody` renders `EmptyState`; `HoopsSize.fabClearance` replaces the per-feature copies; `PickerDialog` is the
kit's list picker.
