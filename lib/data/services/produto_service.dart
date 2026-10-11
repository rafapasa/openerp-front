import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/models.dart';

import 'services.dart';

class ProdutoService {
  final ApiService _apiService;
  ProdutoService(this._apiService);

  Future<PaginatedResponse<ProdutoModel>> getProdutos({
    int page = 1,
    int limit = 20,
    int? categoriaId,
    bool? disponivel,
    String? nome,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (disponivel != null) 'disponivel': disponivel,
      if (nome != null && nome.isNotEmpty) 'nome': nome,
    };

    final response = await _apiService.get('/produtos', queryParameters: queryParams);
    final paginated = JsonHelper.extractPaginated(response.data);
    return PaginatedResponse<ProdutoModel>.fromJson(
      paginated,
      (json) => ProdutoModel.fromJson(JsonHelper.asMap(json)),
    );
  }

  Future<ProdutoModel> getProdutoById(int id) async {
    final response = await _apiService.get('/produtos/$id');
    final Map<String, dynamic> data = response.data is Map
        ? JsonHelper.asMap(response.data['data'] ?? response.data)
        : <String, dynamic>{};
    return ProdutoModel.fromJson(data);
  }

  Future<ProdutoModel> createProduto(Map<String, dynamic> body) async {
    final response = await _apiService.post('/produtos', data: body);
    final map = JsonHelper.asMap(response.data);
    final data = JsonHelper.asMap(map['data'] ?? map);
    return ProdutoModel.fromJson(data);
  }

  Future<ProdutoModel> updateProduto(int id, Map<String, dynamic> body) async {
    final response = await _apiService.put('/produtos/$id', data: body);
    final map = JsonHelper.asMap(response.data);
    final data = JsonHelper.asMap(map['data'] ?? map);
    return ProdutoModel.fromJson(data);
  }

  Future<void> deleteProduto(int id) async {
    await _apiService.delete('/produtos/$id');
  }

  Future<void> toggleDisponibilidade(int id, bool disponivel) async {
    await _apiService.patch('/produtos/$id/disponibilidade', data: {'disponivel': disponivel});
  }

  // ============================================================
  // 🔤 Tokens do produto
  // ============================================================
  Future<List<ProdutoTokenModel>> listarTokens(int produtoId) async {
    final response = await _apiService.get('/produtos/$produtoId/token');
    final list = JsonHelper.extractList(response.data);
    return list
        .whereType<Map>()
        .map((e) => ProdutoTokenModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ProdutoTokenModel>> criarTokens(
    int produtoId,
    List<ProdutoTokenModel> tokens,
  ) async {
    final response = await _apiService.post(
      '/produtos/$produtoId/token',
      data: tokens.map((e) => e.toCreateJson()).toList(),
    );
    return _parseTokens(response.data);
  }

  Future<List<ProdutoTokenModel>> atualizarTokens(
    int produtoId,
    List<ProdutoTokenModel> tokens,
  ) async {
    final response = await _apiService.put(
      '/produtos/$produtoId/token',
      data: tokens.map((e) => e.toUpdateJson()).toList(),
    );
    return _parseTokens(response.data);
  }

  Future<void> excluirTokens(int produtoId, List<int> ids) async {
    await _apiService.delete('/produtos/$produtoId/token', data: ids);
  }

  List<ProdutoTokenModel> _parseTokens(dynamic raw) {
    final list = JsonHelper.extractList(raw);
    return list
        .whereType<Map>()
        .map((e) => ProdutoTokenModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
