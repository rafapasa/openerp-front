import 'package:dio/dio.dart';
import 'package:front_openerp/data/services/api_service.dart';

/// Fake de [ApiService] para testes de PedidoService (sem rede e sem Hive).
class FakeApiService implements ApiService {
  String? lastMethod;
  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic> responseData;

  FakeApiService({Map<String, dynamic>? responseData})
      : responseData = responseData ?? {};

  Response _ok(String path) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: responseData,
      statusCode: 200,
    );
  }

  @override
  Dio get dio => throw UnimplementedError();

  @override
  bool get isAuthenticated => false;

  @override
  Future<void> setToken(String token) async {}

  @override
  Future<void> setTokenExpires(String tokenExpires) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = queryParameters;
    lastData = null;
    return _ok(path);
  }

  @override
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastData = data;
    return _ok(path);
  }

  @override
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastData = data;
    lastQuery = queryParameters;
    return _ok(path);
  }

  @override
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastData = data;
    return _ok(path);
  }

  @override
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'DELETE';
    lastPath = path;
    lastData = data;
    lastQuery = queryParameters;
    return _ok(path);
  }
}
