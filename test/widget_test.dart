import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coffeclub/app.dart';

void main() {
  testWidgets('La app arranca en la pantalla de login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CoffeClubApp()));
    await tester.pumpAndSettle();

    expect(find.text('BIENVENIDO SOCIO.'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
