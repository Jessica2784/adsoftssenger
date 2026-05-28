import 'package:adsoftssenger/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the chat tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MessengerCloneApp(),
      ),
    );

    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Personas'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });

  testWidgets('people tab switches between contacts and stories', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MessengerCloneApp(),
      ),
    );

    await tester.tap(find.text('Personas'));
    await tester.pumpAndSettle();

    expect(find.text('Contactos'), findsOneWidget);
    expect(find.text('Estados'), findsOneWidget);
    expect(find.text('Perfil disponible'), findsWidgets);
    expect(find.text('En línea'), findsNothing);
    expect(find.text('Desconectado'), findsNothing);

    await tester.tap(find.text('Estados'));
    await tester.pumpAndSettle();

    expect(find.text('Tu estado'), findsOneWidget);
    expect(find.text('Estado reciente'), findsWidgets);
  });
}
