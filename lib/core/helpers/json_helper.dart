class JsonHelper {
  static int toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    if (value is num) return value.toInt();
    return fallback;
  }

  static double toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    if (value is num) return value.toDouble();
    return fallback;
  }

  static String toStr(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static bool toBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return fallback;
  }

  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static DateTime toDateTimeOrNow(dynamic value) => toDateTime(value) ?? DateTime.now();
  static List<T> toList<T>(dynamic value, T Function(dynamic) mapper) {
    if (value == null) return [];
    if (value is List) return value.map(mapper).toList();
    return [];
  }

  // Novo padrão: sempre {data: ...}
  static dynamic extractData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) return responseData['data'];
    return responseData;
  }

  static List<dynamic> extractList(dynamic responseData) {
    final data = extractData(responseData);
    if (data is List) return data;
    return [];
  }

  static Map<String, dynamic> asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static Map<String, dynamic> extractPaginated(dynamic responseData) {
    if (responseData is Map) {
      final map = asMap(responseData);
      if (map.containsKey('data') && map.containsKey('total')) return map;
    }
    // fallback legado
    if (responseData is List) {
      return {
        'data': responseData,
        'total': responseData.length,
        'page': 1,
        'limit': responseData.length,
        'total_pages': 1,
      };
    }
    return {'data': [], 'total': 0, 'page': 1, 'limit': 20, 'total_pages': 1};
  }
}
