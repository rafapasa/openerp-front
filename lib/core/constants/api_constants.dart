class ApiEndpoints {
  static const String login = '/login';
  static const String logout = '/logout';
  static const String dashboard = '/dashboard';

  static const String pedidos = '/pedidos';
  static String pedidoById(int id) => '/pedidos/$id';
  static String pedidoStatus(int id) => '/pedidos/$id/status';

  static const String clientes = '/clientes';
  static String clienteById(int id) => '/clientes/$id';
  static String clientePedidos(int id) => '/clientes/$id/pedidos';
  static String clienteEnderecos(int id) => '/clientes/$id/enderecos';

  static const String produtos = '/produtos';
  static String produtoById(int id) => '/produtos/$id';

  static const String formasPagamento = '/formas-pagamento';
  static String formaPagamentoById(int id) => '/formas-pagamento/$id';

  static const String tenants = '/tenants';
  static String tenantById(int id) => '/tenants/$id';
}
