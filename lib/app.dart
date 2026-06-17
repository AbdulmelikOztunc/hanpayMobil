import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/core/router/app_router.dart';
import 'package:hanpay_mobil/core/theme/app_theme.dart';
import 'package:hanpay_mobil/core/network/notifications_hub.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';

class HanpayApp extends ConsumerWidget {
  const HanpayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final auth = ref.watch(authControllerProvider);
    final localeAsync = ref.watch(localeServiceProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'HANPAY',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: locale.materialLocale,
      supportedLocales: AppLocale.values.map((l) => l.materialLocale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (auth.isBootstrapping || localeAsync.isLoading) {
          return const Material(child: LoadingView(message: 'Yükleniyor...'));
        }
        if (localeAsync.hasError) {
          return Material(
            child: ErrorView(message: 'Dil dosyaları yüklenemedi: ${localeAsync.error}'),
          );
        }
        return NotificationsHubListener(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
