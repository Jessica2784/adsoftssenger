import 'package:adsoftssenger/main.dart';
import 'package:adsoftssenger/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _testApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SessionProvider()),
    ],
    child: const MessengerCloneApp(),
  );
}

void main() {
  testWidgets('shows the chat tab', (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Personas'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });

  testWidgets('people tab opens the real user registration form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.text('Personas'));
    await tester.pump();

    expect(find.text('Contactos'), findsOneWidget);
    expect(find.text('Estados'), findsOneWidget);
    expect(find.text('Agregar usuario'), findsOneWidget);

    await tester.tap(find.text('Agregar usuario'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre para mostrar'), findsOneWidget);
    expect(find.text('Nombre de usuario'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Crear usuario'), findsOneWidget);
  });
}
