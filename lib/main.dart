import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/pokemons_controller.dart';
import 'router/app_router.dart';
import 'services/pokeapi_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('onboarding_seen') ?? false);
  final favorites = FavoritesController(prefs);
  final pokemons = PokemonsController(PokeApiService())..load();
  runApp(
    PokeFlutterApp(
      router: createAppRouter(
        showOnboarding: showOnboarding,
        favorites: favorites,
        pokemons: pokemons,
      ),
    ),
  );
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
