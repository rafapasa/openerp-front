// lib/data/repositories/dashboard_repository.dart
import 'package:front_openerp/data/models/models.dart';
import 'package:front_openerp/data/repositories/local_storage.dart';
import 'package:front_openerp/data/services/services.dart';

class DashboardRepository {
  final DashboardService _dashboardService;

  DashboardRepository(this._dashboardService);

  Future<DashboardModel> getDashboard({bool forceRefresh = false, DateTime? dataInicio, DateTime? dataFim}) async {
    final useCache = dataInicio == null && dataFim == null;

    if (useCache && !forceRefresh && LocalStorage.isCacheValid(LocalStorage.dashboardKey)) {
      final cached = LocalStorage.getData<Map<String, dynamic>>(LocalStorage.dashboardKey);
      if (cached != null) {
        return DashboardModel.fromJson(cached);
      }
    }

    try {
      final dashboard = await _dashboardService.getDashboard(dataInicio: dataInicio, dataFim: dataFim);
      if (useCache) {
        await LocalStorage.saveData(LocalStorage.dashboardKey, dashboard.toJson());
      }
      return dashboard;
    } catch (e) {
      final cached = LocalStorage.getData<Map<String, dynamic>>(LocalStorage.dashboardKey);
      if (cached != null) {
        return DashboardModel.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<DashboardModel> refreshDashboard({DateTime? dataInicio, DateTime? dataFim}) {
    return getDashboard(forceRefresh: true, dataInicio: dataInicio, dataFim: dataFim);
  }

  Future<void> clearCache() async {
    await LocalStorage.clearCache(LocalStorage.dashboardKey);
  }
}
