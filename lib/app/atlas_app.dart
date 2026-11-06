import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/atlas_theme.dart';
import '../core/theme/theme_provider.dart';

class AtlasApp extends ConsumerWidget {
  final GoRouter? routerOverride;

  const AtlasApp({super.key, this.routerOverride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = routerOverride ?? ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ATLAS',
      debugShowCheckedModeBanner: false,
      theme: AtlasTheme.lightTheme,
      darkTheme: AtlasTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
