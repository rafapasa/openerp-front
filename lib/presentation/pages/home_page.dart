// lib/presentation/pages/home_page.dart
// HomePage refatorado com MainLayout responsivo eTools
import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/pages/clientes/clientes_page.dart';
import 'package:front_openerp/presentation/pages/dashboard/dashboard_page.dart';
import 'package:front_openerp/presentation/pages/pedidos/pedidos_page.dart';
import 'package:front_openerp/presentation/pages/categorias/categorias_page.dart';
import 'package:front_openerp/presentation/pages/produtos/produtos_page.dart';
import 'package:front_openerp/presentation/pages/tenants/tenants_page.dart';

import '../layout/main_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [DashboardPage(), PedidosPage(), ClientesPage(), ProdutosPage(), CategoriasPage(), TenantsPage()];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: _pages[_selectedIndex],
    );
  }
}
