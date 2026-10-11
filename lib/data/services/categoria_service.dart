import 'package:front_openerp/core/helpers/json_helper.dart';
import 'package:front_openerp/data/models/categoria_model.dart';
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/services/services.dart';

class CategoriaService {
  final ApiService _api;
  CategoriaService(this._api);

  Future<PaginatedResponse<CategoriaModel>> list({int page = 1, int limit = 50, String? q}) async {
    final response = await _api.get('/categorias', queryParameters: {
      'page': page,
      'limit': limit,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    final paginated = JsonHelper.extractPaginated(response.data);
    return PaginatedResponse<CategoriaModel>.fromJson(
      paginated,
      (json) => CategoriaModel.fromJson(JsonHelper.asMap(json)),
    );
  }

  Future<CategoriaModel> create(Map<String, dynamic> body) async {
    final response = await _api.post('/categorias', data: body);
    final map = JsonHelper.asMap(response.data);
    return CategoriaModel.fromJson(JsonHelper.asMap(map['data'] ?? map));
  }

  Future<CategoriaModel> update(int id, Map<String, dynamic> body) async {
    final response = await _api.put('/categorias/$id', data: body);
    final map = JsonHelper.asMap(response.data);
    return CategoriaModel.fromJson(JsonHelper.asMap(map['data'] ?? map));
  }

  Future<void> delete(int id) async {
    await _api.delete('/categorias/$id');
  }
}
