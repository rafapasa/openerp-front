// test/auth_validation_test.dart
// Valida o fluxo de autenticação corrigido: o estado é lido da persistência
// (LocalStorage/Hive) e considera a expiração do token, funcionando já no
// boot do app (antes de qualquer requisição HTTP).
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:openerp_front/data/repositories/auth_repository.dart';
import 'package:openerp_front/data/repositories/local_storage.dart';
import 'package:openerp_front/data/services/api_service.dart';
import 'package:openerp_front/data/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ApiService apiService;
  late AuthRepository authRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_auth');

    // Simula o path_provider para permitir a inicialização do Hive em testes.
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    await LocalStorage.init();

    apiService = ApiService();
    authRepository = AuthRepository(AuthService(apiService));
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await Hive.close();
  });

  setUp(() async {
    await LocalStorage.clearAll();
  });

  group('Autenticação lida da persistência (não de memória)', () {
    test('sem token salvo => não autenticado', () {
      expect(LocalStorage.getToken(), isNull);
      expect(apiService.isAuthenticated, isFalse);
      expect(authRepository.isAuthenticated, isFalse);
    });

    test('token válido salvo => autenticado logo após o "boot"', () async {
      await LocalStorage.setToken('token-valido');
      await LocalStorage.setTokenExpires('2999-01-01T00:00:00Z');

      // Sem qualquer requisição HTTP (sem interceptor rodando), o estado já
      // precisa refletir o token persistido.
      expect(apiService.isAuthenticated, isTrue);
      expect(authRepository.isAuthenticated, isTrue);
    });

    test('token expirado => não autenticado', () async {
      await LocalStorage.setToken('token-expirado');
      await LocalStorage.setTokenExpires('2020-01-01T00:00:00Z');

      expect(apiService.isAuthenticated, isFalse);
      expect(authRepository.isAuthenticated, isFalse);
    });

    test('token sem data de expiração => não autenticado', () async {
      await LocalStorage.setToken('token-sem-expiracao');

      expect(apiService.isAuthenticated, isFalse);
      expect(authRepository.isAuthenticated, isFalse);
    });

    test('token com data inválida => não autenticado (sem crash)', () async {
      await LocalStorage.setToken('token-com-data-invalida');
      await LocalStorage.setTokenExpires('data-invalida');

      expect(apiService.isAuthenticated, isFalse);
      expect(authRepository.isAuthenticated, isFalse);
    });

    test('logout limpa token e expiração', () async {
      await LocalStorage.setToken('token-x');
      await LocalStorage.setTokenExpires('2999-01-01T00:00:00Z');
      expect(apiService.isAuthenticated, isTrue);

      await apiService.logout();

      expect(LocalStorage.getToken(), isNull);
      expect(LocalStorage.getTokenExpires(), isNull);
      expect(apiService.isAuthenticated, isFalse);
    });
  });
}
