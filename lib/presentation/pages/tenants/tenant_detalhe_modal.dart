import 'package:flutter/material.dart';
import 'package:front_openerp/presentation/widgets/viewport_box.dart';
import 'package:front_openerp/data/models/tenant_model.dart';
import 'package:front_openerp/presentation/theme/app_colors.dart';

import 'tenant_dados_tab.dart';
import 'tenant_configuracoes_tab.dart';
import 'tenant_llm_tab.dart';

Future<void> showTenantDetalheModal(BuildContext context, TenantModel tenant) {
  final isWide = MediaQuery.of(context).size.width >= 720;
  if (isWide) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: caixaDaJanela(context, maxWidth: 720),
          child: TenantDetalheModal(tenant: tenant),
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: TenantDetalheModal(tenant: tenant),
    ),
  );
}

class TenantDetalheModal extends StatefulWidget {
  final TenantModel tenant;
  const TenantDetalheModal({super.key, required this.tenant});

  @override
  State<TenantDetalheModal> createState() => _TenantDetalheModalState();
}

class _TenantDetalheModalState extends State<TenantDetalheModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TenantModel _tenant;

  @override
  void initState() {
    super.initState();
    _tenant = widget.tenant;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          _header(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.business_outlined, size: 18), text: 'Dados'),
              Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Configuracoes'),
              Tab(icon: Icon(Icons.smart_toy_outlined, size: 18), text: 'LLM'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TenantDadosTab(tenant: _tenant, onSaved: (atualizado) => setState(() => _tenant = atualizado)),
                TenantConfiguracoesTab(tenantId: _tenant.id ?? 0),
                TenantLlmTab(tenant: _tenant, onSaved: (atualizado) => setState(() => _tenant = atualizado)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tenant.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (_tenant.cnpj != null && _tenant.cnpj!.isNotEmpty)
                  Text('CNPJ: ${_tenant.cnpj}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tenant.ativo ? AppColors.successBg : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _tenant.ativo ? 'Ativa' : 'Inativa',
              style: TextStyle(
                color: _tenant.ativo ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
