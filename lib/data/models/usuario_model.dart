// lib/data/models/usuario_model.dart
import 'package:front_openerp/data/models/login_model.dart';
import 'package:front_openerp/data/models/tenant_model.dart';

class UsuarioModel {
  final int id;
  final String email;
  final String? nome;
  final String? token;
  final String? tokenExpires;
  final String? role;
  final List<TenantModel>? tenants; // ← Lista de tenants disponíveis
  final int? tenantAtivoId; // ← Tenant que o usuário está usando

  UsuarioModel({
    required this.id,
    required this.email,
    this.nome,
    this.token,
    this.tokenExpires,
    this.role,
    this.tenants,
    this.tenantAtivoId,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    // O backend deve retornar a lista de tenants no login
    List<TenantModel>? tenants;
    if (json['tenants'] != null) {
      tenants = (json['tenants'] as List).map((e) => TenantModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return UsuarioModel(
      id: json['id'],
      email: json['email'] ?? '',
      nome: json['nome'],
      token: json['token'],
      tokenExpires: json['tokenExpires'],
      role: json['role'],
      tenants: tenants,
      tenantAtivoId: json['tenant_ativo_id'],
    );
  }

  /// Constrói o usuário a partir de uma conta retornada pelo POST /login.
  factory UsuarioModel.fromLoginConta(LoginConta conta) {
    return UsuarioModel(
      id: conta.id,
      email: conta.email,
      nome: conta.nome.isEmpty ? null : conta.nome,
      token: conta.token,
      tokenExpires: conta.expiresAt,
      role: conta.role,
      tenants: null,
      tenantAtivoId: conta.tenant.id,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nome': nome,
    'token': token,
    'tenants': tenants?.map((e) => e.toJson()).toList(),
    'role': role,
    'tenant_ativo_id': tenantAtivoId,
  };

  // Getters úteis
  bool get hasMultipleTenants => (tenants?.length ?? 0) > 1;
  TenantModel? get tenantAtivo {
    if (tenantAtivoId == null || tenants == null) return null;
    try {
      return tenants!.firstWhere((t) => t.id == tenantAtivoId);
    } catch (e) {
      return tenants?.first;
    }
  }
}
