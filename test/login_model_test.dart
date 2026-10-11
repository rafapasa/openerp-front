// test/login_model_test.dart
// Testes do parsing da resposta do POST /login (LoginResponseList do backend)
// e da conversão de uma conta (users[i]) para o UsuarioModel.
import 'package:flutter_test/flutter_test.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/models/tenant_model.dart';

void main() {
  group('LoginResultado.fromJson (LoginResponseList)', () {
    test('conta única é parseada corretamente', () {
      final json = <String, dynamic>{
        'count': 1,
        'users': [
          {
            'token': 'jwt-abc',
            'expires_at': '2026-09-06T12:00:00Z',
            'user': {
              'id': 1,
              'tenant': {'id': 2, 'nome': 'Tenant 2'},
              'nome': 'João',
              'email': 'joao@etoolstec.com.br',
              'role': 'admin',
            },
          },
        ],
      };

      final resultado = LoginResultado.fromJson(json);

      expect(resultado.count, 1);
      expect(resultado.contas, hasLength(1));
      expect(resultado.possuiMultiplasContas, isFalse);

      final conta = resultado.contas.first;
      expect(conta.token, 'jwt-abc');
      expect(conta.expiresAt, '2026-09-06T12:00:00Z');
      expect(conta.id, 1);
      expect(conta.tenant.id, 2);
      expect(conta.nome, 'João');
      expect(conta.email, 'joao@etoolstec.com.br');
      expect(conta.role, 'admin');
      expect(conta.roleLabel, 'Administrador');
    });

    test('múltiplas contas (mesmo e-mail em vários tenants)', () {
      final json = <String, dynamic>{
        'count': 2,
        'users': [
          {
            'token': 'jwt-tenant-1',
            'expires_at': '2026-09-06T12:00:00Z',
            'user': {
              'id': 1,
              'tenant': {'id': 1, 'nome': 'Tenant 1'},
              'nome': 'João',
              'email': 'joao@etoolstec.com.br',
              'role': 'admin',
            },
          },
          {
            'token': 'jwt-tenant-2',
            'expires_at': '2026-09-06T12:00:00Z',
            'user': {
              'id': 2,
              'tenant': {'id': 3, 'nome': 'Tenant 3'},
              'nome': 'João',
              'email': 'joao@etoolstec.com.br',
              'role': 'atendente',
            },
          },
        ],
      };

      final resultado = LoginResultado.fromJson(json);

      expect(resultado.count, 2);
      expect(resultado.contas, hasLength(2));
      expect(resultado.possuiMultiplasContas, isTrue);
      expect(resultado.contas[0].token, 'jwt-tenant-1');
      expect(resultado.contas[1].tenant.id, 3);
      expect(resultado.contas[1].roleLabel, 'Atendente');
    });
  });

  group('LoginConta', () {
    test('toJson mantém a estrutura esperada pelo cache', () {
      final conta = LoginConta(
        token: 'jwt-x',
        expiresAt: '2026-09-06T12:00:00Z',
        id: 7,
        tenant: TenantModel(id: 9, nome: 'Tenant 9'),
        nome: 'Maria',
        email: 'maria@etoolstec.com.br',
        role: 'cozinha',
      );

      final json = conta.toJson();
      expect(json['token'], 'jwt-x');
      expect(json['expires_at'], '2026-09-06T12:00:00Z');
      final user = json['user'] as Map<String, dynamic>;
      expect(user['id'], 7);
      expect(user['tenant']['id'], 9);
      expect(user['role'], 'cozinha');
      expect(conta.roleLabel, 'Cozinha');

      // Round-trip: de volta para LoginConta
      final reconvertida = LoginConta.fromJson(json);
      expect(reconvertida.id, conta.id);
      expect(reconvertida.tenant.id, conta.tenant.id);
      expect(reconvertida.token, conta.token);
    });
  });

  group('UsuarioModel.fromLoginConta', () {
    test('converte uma conta do login em UsuarioModel', () {
      final conta = LoginConta(
        token: 'jwt-abc',
        expiresAt: '2026-09-06T12:00:00Z',
        id: 42,
        tenant: TenantModel(id: 10, nome: 'Tenant 10'),
        nome: 'João',
        email: 'joao@etoolstec.com.br',
        role: 'admin',
      );

      final usuario = UsuarioModel.fromLoginConta(conta);

      expect(usuario.id, 42);
      expect(usuario.email, 'joao@etoolstec.com.br');
      expect(usuario.nome, 'João');
      expect(usuario.token, 'jwt-abc');
      expect(usuario.tokenExpires, '2026-09-06T12:00:00Z');
      expect(usuario.tenantAtivoId, 10);
    });
  });
}
