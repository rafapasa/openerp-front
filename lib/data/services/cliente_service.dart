import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/models.dart';

import 'services.dart';

class ClienteService {
  final ApiService _apiService;
  ClienteService(this._apiService);

  Future<PaginatedResponse<ClienteModel>> getClientes({
    int page = 1,
    int limit = 20,
    String? nome,
    String? telefone,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (nome != null && nome.isNotEmpty) 'nome': nome,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
    };

    final response = await _apiService.get('/clientes', queryParameters: queryParams);
    final paginated = JsonHelper.extractPaginated(response.data);
    return PaginatedResponse<ClienteModel>.fromJson(
      paginated,
      (json) => ClienteModel.fromJson(JsonHelper.asMap(json)),
    );
  }

  Future<ClienteModel> getClienteById(int id) async {
    final response = await _apiService.get('/clientes/$id');
    final Map<String, dynamic> data = response.data is Map
        ? JsonHelper.asMap(response.data['data'] ?? response.data)
        : <String, dynamic>{};
    return ClienteModel.fromJson(data);
  }

  Future<List<EnderecoModel>> getEnderecosByCliente(int clienteId) async {
    final response = await _apiService.get('/clientes/$clienteId/enderecos');
    final list = JsonHelper.extractList(response.data);
    return list.map((e) => EnderecoModel.fromJson(JsonHelper.asMap(e))).toList();
  }

  Future<ClienteModel> createCliente({
    required String nome,
    required String telefone,
    String? nomePerfil,
    String? email,
    String? inscricaoFederal,
  }) async {
    final response = await _apiService.post(
      '/clientes',
      data: {
        'nome': nome,
        'telefone': telefone,
        'nome_perfil': (nomePerfil != null && nomePerfil.trim().isNotEmpty) ? nomePerfil.trim() : nome,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (inscricaoFederal != null && inscricaoFederal.trim().isNotEmpty)
          'inscricao_federal': inscricaoFederal.trim(),
      },
    );
    final map = response.data is Map ? JsonHelper.asMap(response.data) : <String, dynamic>{};
    final data = map['data'] is Map<String, dynamic> ? JsonHelper.asMap(map['data'] ?? map) : <String, dynamic>{};
    return ClienteModel.fromJson(data);
  }

  Future<EnderecoModel> createEndereco(int clienteId, Map<String, dynamic> body) async {
    final response = await _apiService.post('/clientes/$clienteId/enderecos', data: body);
    final map = response.data is Map ? JsonHelper.asMap(response.data) : <String, dynamic>{};
    final data = map['data'] is Map<String, dynamic> ? JsonHelper.asMap(map['data'] ?? map) : <String, dynamic>{};
    return EnderecoModel.fromJson(data);
  }

  Future<ClienteModel> updateCliente(int id, Map<String, dynamic> payload) async {
    final response = await _apiService.put('/clientes/$id', data: payload);
    final map = response.data is Map ? JsonHelper.asMap(response.data) : <String, dynamic>{};
    final data = map['data'] is Map<String, dynamic> ? JsonHelper.asMap(map['data'] ?? map) : <String, dynamic>{};
    return ClienteModel.fromJson(data);
  }

  Future<EnderecoModel> updateEndereco(int clienteId, int enderecoId, Map<String, dynamic> body) async {
    final response = await _apiService.patch('/clientes/$clienteId/enderecos/$enderecoId', data: body);
    final map = response.data is Map ? JsonHelper.asMap(response.data) : <String, dynamic>{};
    final data = map['data'] is Map<String, dynamic> ? JsonHelper.asMap(map['data'] ?? map) : <String, dynamic>{};
    return EnderecoModel.fromJson(data);
  }

  Future<void> deleteEndereco(int clienteId, int enderecoId) async {
    await _apiService.delete('/clientes/$clienteId/enderecos/$enderecoId');
  }

  Future<void> setEnderecoPrincipal(int clienteId, int enderecoId) async {
    await _apiService.patch('/clientes/$clienteId/enderecos/$enderecoId/principal');
  }
}
