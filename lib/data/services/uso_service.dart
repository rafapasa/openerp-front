import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/models.dart';

import 'services.dart';

class UsoService {
  final ApiService _apiService;
  UsoService(this._apiService);

  Future<List<UsoModel>> listar({bool? ativo, String? q, int limit = 200}) async {
    final response = await _apiService.get(
      '/usos',
      queryParameters: {
        'page': 1,
        'limit': limit,
        if (ativo != null) 'ativo': ativo,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    final paginated = JsonHelper.extractPaginated(response.data);
    final list = paginated['data'];
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => UsoModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<UsoModel> criar({required String label, String slug = '', String sinonimos = '', bool ativo = true}) async {
    final response = await _apiService.post(
      '/usos',
      data: {'label': label, if (slug.isNotEmpty) 'slug': slug, 'sinonimos': sinonimos, 'ativo': ativo},
    );
    return _unwrap(response.data);
  }

  Future<UsoModel> atualizar(
    int id, {
    required String label,
    String slug = '',
    String sinonimos = '',
    bool? ativo,
  }) async {
    final response = await _apiService.put(
      '/usos/$id',
      data: {
        'label': label,
        if (slug.isNotEmpty) 'slug': slug,
        'sinonimos': sinonimos,
        if (ativo != null) 'ativo': ativo,
      },
    );
    return _unwrap(response.data);
  }

  Future<void> excluir(int id) async {
    await _apiService.delete('/usos/$id');
  }

  Future<ProdutoModel> vincularProduto(int produtoId, List<int> usoIds) async {
    final response = await _apiService.put('/produtos/$produtoId/usos', data: {'uso_ids': usoIds});
    return _unwrapProduto(response.data);
  }

  UsoModel _unwrap(dynamic raw) {
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final data = map['data'] is Map<String, dynamic> ? map['data'] as Map<String, dynamic> : map;
    return UsoModel.fromJson(data);
  }

  ProdutoModel _unwrapProduto(dynamic raw) {
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final data = map['data'] is Map<String, dynamic> ? map['data'] as Map<String, dynamic> : map;
    return ProdutoModel.fromJson(data);
  }
}
