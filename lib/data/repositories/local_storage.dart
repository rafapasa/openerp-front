import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String boxName = 'front_openerp_cache';
  static const String tokenKey = 'auth_token';
  static const String tokenExpiresKey = 'token_expires';
  static const String contasLoginKey = 'contas_login';
  static const String dashboardKey = 'dashboard';
  static const String pedidosKey = 'pedidos';
  static const String produtosKey = 'produtos';
  static const String clientesKey = 'clientes';
  static const String ultimaAtualizacaoKey = 'last_update';

  static late Box _box;

  // Inicializar
  static Future<void> init() async {
    await Hive.initFlutter();

    // Registrar adapters (tipos personalizados)
    // Hive.registerAdapter(StatusPedidoAdapter());
    // Hive.registerAdapter(OrigemPedidoAdapter());

    _box = await Hive.openBox(boxName);
  }

  // Getters
  static Box get box => _box;

  // ============================================================
  // 🔐 Token
  // ============================================================
  static Future<void> setToken(String token) async {
    await _box.put(tokenKey, token);
  }

  static String? getToken() {
    return _box.get(tokenKey);
  }

  static Future<void> setTokenExpires(String tokenExpires) async {
    await _box.put(tokenExpiresKey, tokenExpires);
  }

  static String? getTokenExpires() {
    return _box.get(tokenExpiresKey);
  }

  static Future<void> clearToken() async {
    await _box.delete(tokenKey);
  }

  static Future<void> clearTokenExpires() async {
    await _box.delete(tokenExpiresKey);
  }

  // ============================================================
  // 🔎 Validação de autenticação (fonte única: Hive)
  // ============================================================

  // Token expirado? Considera 1 minuto de folga para evitar chamadas com
  // token já vencido (RFC3339).
  static bool isTokenExpired() {
    final expiresString = getTokenExpires();
    if (expiresString == null) return true;
    try {
      final expiresAt = DateTime.parse(expiresString);
      return DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));
    } catch (_) {
      return true;
    }
  }

  // Existe um token persistido, não vazio e ainda válido?
  static bool hasValidToken() {
    final token = getToken();
    return token != null && token.isNotEmpty && !isTokenExpired();
  }

  // ============================================================
  // 📊 Cache de Dados
  // ============================================================

  // Salvar dados com timestamp
  static Future<void> saveData<T>(String key, T data) async {
    await _box.put(key, data);
    await _box.put('${key}_timestamp', DateTime.now().toIso8601String());
  }

  // Buscar dados
  static T? getData<T>(String key) {
    return _box.get(key);
  }

  // Buscar com timestamp
  static DateTime? getTimestamp(String key) {
    final timestamp = _box.get('${key}_timestamp');
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }

  // Verificar se cache é válido (ex: 5 minutos)
  static bool isCacheValid(String key, {Duration maxAge = const Duration(minutes: 5)}) {
    final timestamp = getTimestamp(key);
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < maxAge;
  }

  // Limpar cache específico
  static Future<void> clearCache(String key) async {
    await _box.delete(key);
    await _box.delete('${key}_timestamp');
  }

  // Limpar todo o cache
  static Future<void> clearAll() async {
    await _box.clear();
  }

  // ============================================================
  // 🗑️ Gerenciamento
  // ============================================================

  // Verificar se tem dados
  static bool hasData(String key) {
    return _box.containsKey(key);
  }

  // Tamanho do cache
  static int get size => _box.length;
}
