import 'package:go_router/go_router.dart';
import 'package:poke_app/widgets/app_scafold.dart';
import '../models/pokemon.dart';
import '../screens/detail_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';

GoRouter createAppRouter({required bool showOnboarding}) => GoRouter(
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
              builder: (_, _) => const HomeScreen(),
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
              builder: (_, _) => const FavoritesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
