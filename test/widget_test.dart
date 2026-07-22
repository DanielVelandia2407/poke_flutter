import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poke_app/controllers/favorites_controller.dart';
import 'package:poke_app/controllers/pokemons_controller.dart';
import 'package:poke_app/main.dart';
import 'package:poke_app/router/app_router.dart';
import 'package:poke_app/services/pokeapi_service.dart';

void main() {
  testWidgets('muestra el onboarding la primera vez', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = PokeApiService();
    await tester.pumpWidget(
      PokeFlutterApp(
        router: createAppRouter(
          showOnboarding: true,
          favorites: FavoritesController(prefs),
          pokemons: PokemonsController(service),
          service: service,
        ),
      ),
    );

    expect(find.text('Bienvenido a PokéFlutter'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });
}
