import 'package:openerp_front/core/helpers/json_helper.dart';

class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int pages;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    final dataList = JsonHelper.extractList(json['data'] ?? json);
    return PaginatedResponse<T>(
      data: dataList.map((e) => fromJsonT(e)).toList(),
      total: JsonHelper.toInt(json['total'], fallback: dataList.length),
      page: JsonHelper.toInt(json['page'], fallback: 1),
      limit: JsonHelper.toInt(json['limit'], fallback: 20),
      pages: JsonHelper.toInt(json['pages'] ?? json['total_pages'], fallback: 1),
    );
  }

  Map<String, dynamic> toJson() => {'data': data, 'total': total, 'page': page, 'limit': limit, 'pages': pages};

  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
}
