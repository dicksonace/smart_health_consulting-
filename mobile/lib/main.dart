import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'store/app_store.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  final store = AppStore();
  final router = AppRouter.create(store);

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: SmartHealthApp(router: router),
    ),
  );
}

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Health Consulting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
