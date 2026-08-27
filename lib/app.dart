import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Root widget of the application
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Job Platform',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,

      // Router
      routerConfig: AppRouter.router,
    );
  }
}
