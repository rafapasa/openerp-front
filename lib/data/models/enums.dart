/// Enum para status do pedido
enum StatusPedido {
  pendente,
  confirmado,
  emPreparo,
  prontoRetirada,
  saiuEntrega,
  entregue,
  cancelado;

  /// Converte string para enum
  static StatusPedido fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pendente':
        return StatusPedido.pendente;
      case 'confirmado':
        return StatusPedido.confirmado;
      case 'preparando':
      case 'em_preparo':
      case 'em-preparo':
        return StatusPedido.emPreparo;
      case 'pronto':
      case 'pronto_retirada':
      case 'pronto-retirada':
        return StatusPedido.prontoRetirada;
      case 'saiu_entrega':
      case 'saiu-entrega':
      case 'saiu_para_entrega':
        return StatusPedido.saiuEntrega;
      case 'entregue':
        return StatusPedido.entregue;
      case 'cancelado':
        return StatusPedido.cancelado;
      default:
        return StatusPedido.pendente;
    }
  }

  /// Converte enum para string (usado na API)
  String toStringValue() {
    switch (this) {
      case StatusPedido.pendente:
        return 'pendente';
      case StatusPedido.confirmado:
        return 'confirmado';
      case StatusPedido.emPreparo:
        return 'em_preparo';
      case StatusPedido.prontoRetirada:
        return 'pronto_retirada';
      case StatusPedido.saiuEntrega:
        return 'saiu_para_entrega';
      case StatusPedido.entregue:
        return 'entregue';
      case StatusPedido.cancelado:
        return 'cancelado';
    }
  }

  StatusPedido? get proximoOperacional {
    switch (this) {
      case StatusPedido.pendente:
        return StatusPedido.confirmado;
      case StatusPedido.confirmado:
        return StatusPedido.emPreparo;
      case StatusPedido.emPreparo:
        return null; // decide no PedidoModel (entrega vs retirada)
      case StatusPedido.prontoRetirada:
        return StatusPedido.entregue;
      case StatusPedido.saiuEntrega:
        return StatusPedido.entregue;
      default:
        return null;
    }
  }

  String get proximoLabel {
    switch (proximoOperacional) {
      case StatusPedido.confirmado:
        return 'Confirmar';
      case StatusPedido.emPreparo:
        return 'Preparar';
      case StatusPedido.saiuEntrega:
        return 'Saiu p/ entrega';
      case StatusPedido.entregue:
        return 'Entregar';
      default:
        return '';
    }
  }

  String get label {
    switch (this) {
      case StatusPedido.pendente:
        return 'Pendente';
      case StatusPedido.confirmado:
        return 'Confirmado';
      case StatusPedido.emPreparo:
        return 'Em preparo';
      case StatusPedido.prontoRetirada:
        return 'Pronto p/ retirar';
      case StatusPedido.saiuEntrega:
        return 'Saiu p/ entrega';
      case StatusPedido.entregue:
        return 'Entregue';
      case StatusPedido.cancelado:
        return 'Cancelado';
    }
  }

  String get colorHex {
    switch (this) {
      case StatusPedido.pendente:
        return '#FF9800';
      case StatusPedido.confirmado:
        return '#2196F3';
      case StatusPedido.emPreparo:
        return '#9C27B0';
      case StatusPedido.prontoRetirada:
        return '#00897B';
      case StatusPedido.saiuEntrega:
        return '#1565C0';
      case StatusPedido.entregue:
        return '#4CAF50';
      case StatusPedido.cancelado:
        return '#F44336';
    }
  }

  String get iconName {
    switch (this) {
      case StatusPedido.pendente:
        return 'pending';
      case StatusPedido.confirmado:
        return 'check_circle';
      case StatusPedido.emPreparo:
        return 'build';
      case StatusPedido.prontoRetirada:
        return 'storefront';
      case StatusPedido.saiuEntrega:
        return 'local_shipping';
      case StatusPedido.entregue:
        return 'delivery';
      case StatusPedido.cancelado:
        return 'cancel';
    }
  }

  bool get isCozinha => this == StatusPedido.emPreparo;
}

/// Enum para origem do pedido
enum OrigemPedido {
  whatsapp,
  web,
  app,
  presencial,
  telefone;

  static OrigemPedido fromString(String value) {
    switch (value.toLowerCase()) {
      case 'whatsapp':
        return OrigemPedido.whatsapp;
      case 'web':
        return OrigemPedido.web;
      case 'dashboard':
        return OrigemPedido.web;
      case 'app':
        return OrigemPedido.app;
      case 'presencial':
        return OrigemPedido.presencial;
      case 'telefone':
        return OrigemPedido.telefone;
      default:
        return OrigemPedido.whatsapp;
    }
  }

  String toStringValue() {
    switch (this) {
      case OrigemPedido.whatsapp:
        return 'whatsapp';
      case OrigemPedido.web:
        return 'dashboard';
      case OrigemPedido.app:
        return 'app';
      case OrigemPedido.presencial:
        return 'presencial';
      case OrigemPedido.telefone:
        return 'telefone';
    }
  }

  String get label {
    switch (this) {
      case OrigemPedido.whatsapp:
        return 'WhatsApp';
      case OrigemPedido.web:
        return 'Web';
      case OrigemPedido.app:
        return 'App';
      case OrigemPedido.presencial:
        return 'Presencial';
      case OrigemPedido.telefone:
        return 'Telefone';
    }
  }
}

enum TenantStatus {
  ativo,
  inativo,
  bloqueado,
  suspenso;

  static TenantStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ativo':
        return TenantStatus.ativo;
      case 'inativo':
        return TenantStatus.inativo;
      case 'bloqueado':
        return TenantStatus.bloqueado;
      case 'suspenso':
        return TenantStatus.suspenso;
      default:
        return TenantStatus.ativo;
    }
  }

  String toStringValue() {
    switch (this) {
      case TenantStatus.ativo:
        return 'ativo';
      case TenantStatus.inativo:
        return 'inativo';
      case TenantStatus.bloqueado:
        return 'bloqueado';
      case TenantStatus.suspenso:
        return 'suspenso';
    }
  }

  String get label {
    switch (this) {
      case TenantStatus.ativo:
        return 'Ativo';
      case TenantStatus.inativo:
        return 'Inativo';
      case TenantStatus.bloqueado:
        return 'Bloqueado';
      case TenantStatus.suspenso:
        return 'Suspenso';
    }
  }

  String get colorHex {
    switch (this) {
      case TenantStatus.ativo:
        return '#4CAF50';
      case TenantStatus.inativo:
        return '#9E9E9E';
      case TenantStatus.bloqueado:
        return '#F44336';
      case TenantStatus.suspenso:
        return '#FF9800';
    }
  }
}
