import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/http/request_context.dart';
import '../core/l10n/locale_controller.dart';
import '../core/session/session_providers.dart';
import '../l10n/gen/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class HoopsApp extends ConsumerWidget {
  const HoopsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Publish ambient request values for the HTTP interceptors.
    final requestContext = ref.watch(requestContextProvider);
    requestContext.tenantId = ref.watch(activeTenantIdProvider);
    final locale = ref.watch(effectiveLocaleProvider);
    requestContext.languageCode = locale.languageCode;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
    );
  }
}
