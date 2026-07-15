import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('onboarding_seen') ?? false);
  runApp(PokeFlutterApp(router: createAppRouter(showOnboarding: showOnboarding)));
}

class PokeFlutterApp extends StatelessWidget {
  final GoRouter router;

  const PokeFlutterApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'PokéFlutter',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    routerConfig: router,
  );
}
