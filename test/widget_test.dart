// test/widget_test.dart
// Smoke test da aplicação: verifica a inicialização (SplashPage) e a
// navegação para a tela de login quando não há sessão salva.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/repositories/local_storage.dart';
import 'package:front_openerp/main.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, (
      call,
    ) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    await LocalStorage.init();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await Hive.close();
  });

  testWidgets('App inicializa na SplashPage e navega para o Login', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    // Splash atual (eTools): título OpenERP + loading — não existe mais "Front-OpenERP".
    expect(find.text('OpenERP'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo!'), findsOneWidget);
  });
}
