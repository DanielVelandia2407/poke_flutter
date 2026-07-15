import 'package:flutter_test/flutter_test.dart';

import 'package:poke_app/main.dart';
import 'package:poke_app/router/app_router.dart';

void main() {
  testWidgets('muestra el onboarding la primera vez', (tester) async {
    await tester.pumpWidget(
      PokeFlutterApp(router: createAppRouter(showOnboarding: true)),
    );

    expect(find.text('Bienvenido a PokéFlutter'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });
}
