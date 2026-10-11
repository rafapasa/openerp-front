import 'enums.dart';
import 'pedido_model.dart';

const transicoesPedido = <StatusPedido, Set<StatusPedido>>{
  StatusPedido.pendente: {StatusPedido.confirmado, StatusPedido.cancelado},
  StatusPedido.confirmado: {StatusPedido.emPreparo, StatusPedido.cancelado},
  StatusPedido.emPreparo: {StatusPedido.saiuEntrega, StatusPedido.prontoRetirada, StatusPedido.cancelado},
  StatusPedido.prontoRetirada: {StatusPedido.entregue, StatusPedido.cancelado},
  StatusPedido.saiuEntrega: {StatusPedido.entregue, StatusPedido.cancelado},
  StatusPedido.entregue: {},
  StatusPedido.cancelado: {},
};

bool pedidoPodeMoverPara(PedidoModel pedido, StatusPedido dest) {
  if (pedido.status == dest) return false;
  if (dest == StatusPedido.saiuEntrega && !pedido.isEntrega) return false;
  if (dest == StatusPedido.prontoRetirada && pedido.isEntrega) return false;
  return transicoesPedido[pedido.status]?.contains(dest) ?? false;
}
