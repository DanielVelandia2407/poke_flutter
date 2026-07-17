import 'package:go_router/go_router.dart';
import 'package:poke_app/widgets/app_scafold.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/pokemons_controller.dart';
import '../models/pokemon.dart';
import '../screens/detail_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';

GoRouter createAppRouter({
  required bool showOnboarding,
  required FavoritesController favorites,
  required PokemonsController pokemons,
}) => GoRouter(
  initialLocation: showOnboarding ? '/onboarding' : '/',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, _) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  HomeScreen(favorites: favorites, pokemons: pokemons),
              routes: [
                GoRoute(
                  path: '/pokemon/:id',
                  builder: (context, state) => DetailScreen(
                    id: state.pathParameters['id']!,
                    pokemon: state.extra as Pokemon?,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              name: 'favorites',
              builder: (_, _) =>
                  FavoritesScreen(favorites: favorites, pokemons: pokemons),
            ),
          ],
        ),
      ],
    ),
  ],
);
