// lib/main.dart
import 'package:flutter/material.dart';
import 'package:front_openerp/data/repositories/repositories.dart';
import 'package:front_openerp/data/repositories/tenant_repository.dart';
import 'package:front_openerp/data/services/categoria_service.dart';
import 'package:front_openerp/data/services/services.dart';
import 'package:front_openerp/data/services/tenant_service.dart';
import 'package:front_openerp/presentation/pages/pages.dart';
import 'package:front_openerp/presentation/providers/providers.dart';
import 'package:front_openerp/presentation/providers/tenant_provider.dart';
import 'package:front_openerp/presentation/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar LocalStorage
  await LocalStorage.init();

  runApp(buildApp());
}

/// Constrói a árvore de widgets principal do app com todos os providers.
Widget buildApp() {
  return MultiProvider(
    providers: [
      // Services
      Provider<ApiService>(create: (_) => ApiService()),
      Provider<AuthService>(create: (context) => AuthService(context.read<ApiService>())),
      Provider<DashboardService>(create: (context) => DashboardService(context.read<ApiService>())),
      Provider<PedidoService>(create: (context) => PedidoService(context.read<ApiService>())),
      Provider<ClienteService>(create: (context) => ClienteService(context.read<ApiService>())),
      Provider<ProdutoService>(create: (context) => ProdutoService(context.read<ApiService>())),
      Provider<TenantService>(create: (context) => TenantService(context.read<ApiService>())),
      Provider<UsoService>(create: (context) => UsoService(context.read<ApiService>())),
      Provider<CategoriaService>(create: (context) => CategoriaService(context.read<ApiService>())),

      // Repositories
      Provider<AuthRepository>(create: (context) => AuthRepository(context.read<AuthService>())),
      Provider<DashboardRepository>(create: (context) => DashboardRepository(context.read<DashboardService>())),
      Provider<PedidoRepository>(create: (context) => PedidoRepository(context.read<PedidoService>())),
      Provider<ClienteRepository>(create: (context) => ClienteRepository(context.read<ClienteService>())),
      Provider<ProdutoRepository>(create: (context) => ProdutoRepository(context.read<ProdutoService>())),
      Provider<TenantRepository>(create: (context) => TenantRepository(context.read<TenantService>())),

      // Providers
      ChangeNotifierProvider<AuthProvider>(create: (context) => AuthProvider(context.read<AuthRepository>())),
      ChangeNotifierProvider<DashboardProvider>(
        create: (context) => DashboardProvider(context.read<DashboardRepository>()),
      ),
      ChangeNotifierProvider<PedidoProvider>(create: (context) => PedidoProvider(context.read<PedidoRepository>())),
      ChangeNotifierProvider<ClienteProvider>(create: (context) => ClienteProvider(context.read<ClienteRepository>())),
      ChangeNotifierProvider<ProdutoProvider>(create: (context) => ProdutoProvider(context.read<ProdutoRepository>())),
      ChangeNotifierProvider<TenantProvider>(create: (context) => TenantProvider(context.read<TenantRepository>())),
    ],
    child: const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Front-OpenERP',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: true,
      home: const SplashPage(),
    );
  }
}
