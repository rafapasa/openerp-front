#!/bin/bash
# create_v1.1_front_back_issues.sh
# Cria issues detalhadas no FRONT (rafapasa/front-openerp) e BACK (rafapasa/mcp-server-openerp)
# alinhadas ao padrão: modal + quick edit + campos preparados para API futura.
#
# Uso:
#   chmod +x create_v1.1_front_back_issues.sh
#   ./create_v1.1_front_back_issues.sh
#
# Requer: gh cli autenticado (gh auth login) com escopos repo + project (opcional)

set -euo pipefail

FRONT_REPO="${FRONT_REPO:-rafapasa/front-openerp}"
BACK_REPO="${BACK_REPO:-rafapasa/mcp-server-openerp}"
FRONT_MILESTONE_TITLE="v1.1 - Front Operacional - Go Live"
BACK_MILESTONE_TITLE="v1.0 - Go Live Produção"
FRONT_PROJECT_TITLE="${FRONT_PROJECT_TITLE:-FrontEnd-mcp-server-openerp}"
BACK_PROJECT_TITLE="${BACK_PROJECT_TITLE:-}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

ensure_label() {
  local repo=$1
  local label=$2
  local color=${3:-ededed}
  if gh api "repos/$repo/labels/$label" >/dev/null 2>&1; then
    return
  fi
  echo "  → label $label em $repo"
  gh api --method POST "repos/$repo/labels" \
    --raw-field "name=$label" \
    --raw-field "color=$color" >/dev/null || true
}

find_milestone() {
  local repo=$1
  local title=$2
  MILESTONE_TITLE="$title" gh api --paginate "repos/$repo/milestones?state=all&per_page=100" \
    --jq '.[] | select(.title == env.MILESTONE_TITLE) | .number' | head -n 1
}

ensure_milestone() {
  local repo=$1
  local title=$2
  local description=$3
  local num
  num="$(find_milestone "$repo" "$title")"
  if [[ -z "$num" ]]; then
    echo "  → criando milestone: $title ($repo)"
    num="$(
      gh api --method POST "repos/$repo/milestones" \
        --raw-field "title=$title" \
        --raw-field "description=$description" \
        --raw-field state=open --jq '.number'
    )"
  else
    echo "  → milestone #$num ($title) em $repo"
  fi
  echo "$num"
}

create_issue() {
  local repo=$1
  local title=$2
  local body=$3
  local labels=$4
  local milestone=$5

  echo "→ [$repo] $title"
  local -a label_args=()
  local -a label_list=()
  IFS=',' read -ra label_list <<< "$labels"
  for label in "${label_list[@]}"; do
    label="$(echo "$label" | xargs)"
    [[ -z "$label" ]] && continue
    ensure_label "$repo" "$label"
    label_args+=(--raw-field "labels[]=$label")
  done

  local url
  url="$(
    gh api --method POST "repos/$repo/issues" \
      --raw-field "title=$title" \
      --raw-field "body=$body" \
      --field "milestone=$milestone" \
      "${label_args[@]}" \
      --jq '.html_url'
  )"
  echo "  ✓ $url"
}

# ---------------------------------------------------------------------------
# FRONT labels + milestone
# ---------------------------------------------------------------------------
echo "=== FRONT: $FRONT_REPO ==="
for label in front security P0 realtime P1 whatsapp dashboard P2 ux backend-ready; do
  ensure_label "$FRONT_REPO" "$label"
done

FRONT_MS="$(ensure_milestone "$FRONT_REPO" "$FRONT_MILESTONE_TITLE" \
  "Dashboard operacional: pedidos, modal detalhe, quick edit, notificações, handoff. Branch base: dev. Stack: Flutter Web/Mobile + Provider + Dio.")"

# ---------------------------------------------------------------------------
# BACK labels + milestone
# ---------------------------------------------------------------------------
echo "=== BACK: $BACK_REPO ==="
for label in backend api P0 P1 pedidos pagamento status timeline; do
  ensure_label "$BACK_REPO" "$label"
done

BACK_MS="$(ensure_milestone "$BACK_REPO" "$BACK_MILESTONE_TITLE" \
  "API produção: pedidos, status com motivo, pagamento, histórico/timeline, SSE. Go + Fiber + JWT + multi-tenant.")"

# ===========================================================================
# BACKEND ISSUES
# ===========================================================================

create_issue "$BACK_REPO" \
"[API] Pedidos: PATCH status com motivo + histórico (timeline)" \
"## Contexto
O front operacional (modal de detalhe) precisa:
1. Atualizar status com **motivo obrigatório** em cancelamento/recusa
2. Exibir **timeline** de mudanças de status

Hoje: \`PATCH /api/v1/pedidos/:id/status\` aceita apenas \`{ \"status\": \"confirmado\" }\`.

## Contrato desejado

### Request — PATCH \`/api/v1/pedidos/:id/status\`
\`\`\`json
{
  \"status\": \"cancelado\",
  \"motivo\": \"Cliente pediu para cancelar — item em falta\"
}
\`\`\`

Regras:
- \`motivo\` **obrigatório** quando \`status\` ∈ \`cancelado\` (e opcionalmente \`recusado\`)
- \`motivo\` opcional/ignorado nos demais status
- Validar transição de status (ex.: não voltar de \`entregue\` para \`pendente\`)

### Response 200
\`\`\`json
{
  \"data\": {
    \"id\": 128,
    \"status\": \"cancelado\",
    \"motivo_cancelamento\": \"Cliente pediu para cancelar — item em falta\",
    \"updated_at\": \"2026-09-10T01:15:00Z\"
  }
}
\`\`\`

### Novo endpoint (ou embed) — histórico
Opção A — embed no GET pedido:
\`\`\`json
{
  \"data\": {
    \"id\": 128,
    \"status\": \"em_preparo\",
    \"historico\": [
      {
        \"id\": 1,
        \"status_anterior\": null,
        \"status_novo\": \"pendente\",
        \"motivo\": null,
        \"usuario_id\": null,
        \"usuario_nome\": \"sistema\",
        \"created_at\": \"2026-09-10T00:50:00Z\"
      },
      {
        \"id\": 2,
        \"status_anterior\": \"pendente\",
        \"status_novo\": \"confirmado\",
        \"motivo\": null,
        \"usuario_id\": 1,
        \"usuario_nome\": \"Rafael\",
        \"created_at\": \"2026-09-10T00:52:00Z\"
      },
      {
        \"id\": 3,
        \"status_anterior\": \"confirmado\",
        \"status_novo\": \"em_preparo\",
        \"motivo\": null,
        \"usuario_id\": 1,
        \"usuario_nome\": \"Rafael\",
        \"created_at\": \"2026-09-10T01:00:00Z\"
      }
    ]
  }
}
\`\`\`

Opção B — \`GET /api/v1/pedidos/:id/historico\` com o mesmo array.

## Status canônicos (alinhar com front)
\`pendente | confirmado | em_preparo | pronto | saiu_entrega | entregue | cancelado\`

> Front hoje usa \`preparando\` em alguns pontos — documentar alias ou migrar 100% para \`em_preparo\`.

## Tarefas
- [ ] Aceitar \`motivo\` no PATCH status
- [ ] Persistir \`motivo_cancelamento\` no pedido
- [ ] Tabela/coleção \`pedido_status_historico\` (ou JSONB)
- [ ] Registrar cada transição com user + timestamp
- [ ] Expor histórico no GET pedido ou endpoint dedicado
- [ ] Validação de transição + 400 com mensagem clara
- [ ] Testes unitários / integração

## Aceite
- Cancelar sem motivo → 400
- Cancelar com motivo → 200 e motivo persistido
- GET pedido retorna timeline ordenada cronologicamente
- Multi-tenant: só pedido do \`X-Tenant-ID\`

## Fora de escopo
- Front (já prepara UI nullable até este endpoint existir)
" "backend,api,P0,pedidos,status,timeline" "$BACK_MS"

create_issue "$BACK_REPO" \
"[API] Pedidos: PATCH pagamento (marcar como pago)" \
"## Contexto
Operador no modal de detalhe precisa marcar pedido como **pago** sem abrir ERP.

Pedido já pode trazer \`pagamentos: [{ forma_pagamento_id, forma, valor, status }]\` no GET.

## Contrato desejado

### PATCH \`/api/v1/pedidos/:id/pagamento\`
\`\`\`json
{
  \"pago\": true,
  \"forma_pagamento_id\": 1,
  \"valor\": 57.80,
  \"observacao\": \"PIX confirmado no app\"
}
\`\`\`

### Response 200
\`\`\`json
{
  \"data\": {
    \"id\": 128,
    \"pago\": true,
    \"pago_em\": \"2026-09-10T01:20:00Z\",
    \"pagamentos\": [
      {
        \"id\": 10,
        \"forma_pagamento_id\": 1,
        \"forma\": \"PIX\",
        \"valor\": 57.80,
        \"status\": \"pago\",
        \"pago_em\": \"2026-09-10T01:20:00Z\"
      }
    ]
  }
}
\`\`\`

### Alternativa mínima (se preferir reutilizar registro existente)
\`PATCH /api/v1/pedidos/:id/pagamentos/:pagamento_id\`
\`\`\`json
{ \"status\": \"pago\" }
\`\`\`

## Tarefas
- [ ] Endpoint PATCH pagamento (ou atualizar status do pagamento aninhado)
- [ ] Campos no pedido: \`pago\` (bool), \`pago_em\` (timestamp)
- [ ] Idempotência: marcar pago de novo não quebra
- [ ] Auditoria simples (quem marcou)
- [ ] 404 se pedido de outro tenant

## Aceite
- Após PATCH, GET pedido reflete \`pago: true\` e status do pagamento
- Front consegue botão \"Marcar como Pago\" com feedback imediato

## Dependência front
Issue de modal detalhe já terá UI + model nullable; liga quando este endpoint estiver pronto.
" "backend,api,P0,pedidos,pagamento" "$BACK_MS"

create_issue "$BACK_REPO" \
"[API] Pedidos: alinhar enum de status (em_preparo, pronto, saiu_entrega)" \
"## Problema
Dashboard e exemplos de API usam: \`pendente, confirmado, em_preparo, pronto, entregue, cancelado\`.
Front legado usa \`preparando\`. Falta status operacional **saiu_entrega** para o kanban/modal.

## Objetivo
Documentar e implementar status canônicos únicos:

| status         | Uso operacional        |
|----------------|------------------------|
| pendente       | Novo / aguardando      |
| confirmado     | Aceito pela loja       |
| em_preparo     | Cozinha                |
| pronto         | Pronto para retirada/entrega |
| saiu_entrega   | Saiu para entrega      |
| entregue       | Concluído              |
| cancelado      | Recusado/cancelado     |

## Tarefas
- [ ] Migration / constraint / enum no banco
- [ ] Aceitar alias \`preparando\` → \`em_preparo\` (compat temporária) **ou** breaking change documentado
- [ ] Atualizar dashboard aggregations
- [ ] Atualizar OpenAPI / doc HTML
- [ ] Changelog para o front

## Response exemplo (lista)
\`\`\`json
{
  \"data\": [ { \"id\": 1, \"status\": \"saiu_entrega\", \"total\": 57.8 } ],
  \"total\": 1, \"page\": 1, \"limit\": 20, \"total_pages\": 1
}
\`\`\`
" "backend,api,P1,pedidos,status" "$BACK_MS"

# ===========================================================================
# FRONT ISSUES
# ===========================================================================

create_issue "$FRONT_REPO" \
"[Front] #26 Detalhe do Pedido — Modal + ações operacionais (quick edit)" \
"## Objetivo
Ao clicar no **card** do pedido, abrir **modal** (não navegar para página full) com ações operacionais.

**Padrão de produto (obrigatório neste e nos próximos):**
- Detalhe / edição → **modal**
- Edição de dados → **quick edit** + notificação sutil “Salvo”
- Criação de cadastro → botão **Criar / Salvar**
- Funcionar **Web + Android + iOS**

## Mock de tela (desejável)

\`\`\`
┌─────────────────────────────────────────────────────────┐
│  Pedido #128                          pendente    [X]   │
│  R\$ 57,80 · WhatsApp · há 12 min                        │
├─────────────────────────────────────────────────────────┤
│  CLIENTE                                                │
│  João Silva                                             │
│  [📞 Ligar]  [💬 WhatsApp]  [📍 Maps]                   │
│  Rua Assis Brasil, 123 — Centro, Xanxerê/SC             │
├─────────────────────────────────────────────────────────┤
│  ITENS                                                  │
│  2× X-Salada (sem cebola)              R\$ 51,80         │
│  1× Coca 350ml                         R\$  6,00         │
├─────────────────────────────────────────────────────────┤
│  PAGAMENTO                                              │
│  PIX · pendente                                         │
│  [✓ Marcar como Pago]                                   │
├─────────────────────────────────────────────────────────┤
│  AÇÕES DE STATUS                                        │
│  [Confirmar] [Em preparo] [Pronto] [Saiu p/ entrega]    │
│  [Entregue]  [Recusar…]                                 │
├─────────────────────────────────────────────────────────┤
│  TIMELINE                                               │
│  • 00:50  pendente (sistema)                            │
│  • 00:52  confirmado (Rafael)                           │
├─────────────────────────────────────────────────────────┤
│  [🖨 Imprimir cupom 80mm]                                │
└─────────────────────────────────────────────────────────┘
\`\`\`

- **Web:** \`Dialog\` largo (max ~560–640px), scroll interno  
- **Mobile:** \`showModalBottomSheet\` (draggable, 90% altura)

## Tarefas
- [ ] Widget \`PedidoDetalheModal\` (shared web/mobile)
- [ ] Clique no card em \`PedidosPage\` abre modal
- [ ] Seção cliente: \`tel:\`, \`https://wa.me/<digits>\`, Maps com endereço
- [ ] Lista de itens + observações
- [ ] Botões de status via \`PATCH /api/v1/pedidos/:id/status\` (API atual)
- [ ] Recusar: dialog com motivo → status \`cancelado\` (motivo no model local até API)
- [ ] Marcar como Pago: UI + stub/provider (até API de pagamento)
- [ ] Timeline visual (created/updated + histórico quando API existir)
- [ ] Cupom 80mm + print (web: \`window.print\`; mobile: preview/share se possível)
- [ ] Snackbar/toast discreto pós quick action (“Status atualizado”, “Salvo”)
- [ ] Model: campos nullable \`motivoCancelamento\`, \`pago\`, \`pagoEm\`, \`historico\`, \`pagamentos\`
- [ ] Alinhar enum status com API (\`em_preparo\`, \`pronto\`, \`saiu_entrega\`)

## Fora de escopo (issues de back + follow-up)
- PATCH status **com motivo** no servidor
- PATCH pagamento real
- SSE / som de novo pedido

## Aceite
- Modal abre em <300ms após clique
- Status muda e lista atualiza sem sair do modal
- Layout legível em phone e desktop
- Nenhum crash se campos novos vierem null da API

## Branch sugerida
\`feature/pedidos-modal-detalhe\` a partir de \`dev\`
" "front,P0,ux" "$FRONT_MS"

create_issue "$FRONT_REPO" \
"[Front] Padrão global: Modal + Quick Edit (design system de interação)" \
"## Objetivo
Documentar e aplicar o padrão de interação definido no Go Live:

| Ação | UX |
|------|-----|
| Ver detalhe | Modal |
| Editar campo / status | Quick edit + toast sutil “Salvo” |
| Criar registro novo | Tela/form com **Criar** ou **Salvar** |

## Mock — quick edit feedback
\`\`\`
┌──────────────────────────────┐
│  Status: em_preparo          │
│  ─────────────────────────   │
│  [toast] ✓ Salvo             │  ← 1.5s, baixo contraste, canto
└──────────────────────────────┘
\`\`\`

## Tarefas
- [ ] Doc curta em \`AGENTS.md\` ou \`docs/ux-patterns.md\`
- [ ] Helper \`showSavedSnack(context)\` padronizado (cor, duração, posição)
- [ ] Checklist para novas telas (clientes, produtos, tenants)
- [ ] (Opcional) Widget base \`AppDetailModal\` com header/actions/scroll

## Aceite
- Qualquer PR de UI nova referencia o padrão
- Toast de save não bloqueia e não grita (sem dialog de sucesso)

## Relacionado
Depende/usa o modal de pedidos (#26) como referência de implementação.
" "front,P1,ux" "$FRONT_MS"

create_issue "$FRONT_REPO" \
"[Front] Pedidos: conectar motivo + pagamento quando API estiver pronta" \
"## Objetivo
Ligar a UI já preparada no modal de detalhe aos endpoints de backend.

## Pré-requisitos (back)
- PATCH status com \`motivo\`
- PATCH pagamento / campos \`pago\`, \`pago_em\`
- Histórico no GET pedido

## Tarefas
- [ ] \`PedidoService.updateStatus(id, status, {String? motivo})\`
- [ ] \`PedidoService.marcarPago(id, ...)\`
- [ ] Provider atualiza lista + modal sem reload completo
- [ ] Validação: recusar sem motivo não chama API
- [ ] Timeline real a partir de \`historico\`

## Aceite
- Cancelar com motivo persiste e reaparece ao reabrir modal
- Marcar pago reflete badge no card da lista
" "front,P1,backend-ready" "$FRONT_MS"

create_issue "$FRONT_REPO" \
"[Front] Kanban operacional de pedidos (4 colunas)" \
"## Descrição
Tela principal operacional em colunas:

| NOVOS | EM PREPARO | SAIU P/ ENTREGA | CONCLUÍDO |
|-------|------------|-----------------|-----------|
| pendente / confirmado | em_preparo / pronto | saiu_entrega | entregue |

Card: #ID, cliente, resumo itens, valor, forma/status pgto, tempo desde criação (destaque >15min), endereço curto.

## Mock
\`\`\`
┌──────────┬──────────┬──────────┬──────────┐
│  NOVOS   │ PREPARO  │  SAIU    │ CONCLUÍDO│
│ ┌──────┐ │ ┌──────┐ │          │          │
│ │#128  │ │ │#120  │ │          │          │
│ │João  │ │ │Maria │ │          │          │
│ │R\$57  │ │ │R\$32  │ │          │          │
│ │12min │ │ │ 5min │ │          │          │
│ └──────┘ │ └──────┘ │          │          │
└──────────┴──────────┴──────────┴──────────┘
\`\`\`

## Tarefas
- [ ] Layout responsivo (horizontal scroll no mobile / grid no web)
- [ ] Clique no card → modal detalhe (issue #26)
- [ ] Ação rápida de status (botão ou drag se viável sem lib pesada)
- [ ] Pull-to-refresh + polling opcional 15s (até SSE)
- [ ] Cores por SLA (>15min)

## Aceite
- Pedidos agrupados corretamente por status
- Modal abre a partir do card
- Web e mobile utilizáveis

## Nota
Script legado citava Riverpod; **stack do repo é Provider** — manter Provider.
" "front,P0,ux" "$FRONT_MS"

create_issue "$FRONT_REPO" \
"[Front] #24 api_service — JWT refresh + X-Tenant-ID + logout seguro" \
"## Problema
api_service precisa fechar o ciclo de segurança alinhado ao backend multi-tenant.

## Tarefas
- [ ] Interceptor Dio: JWT em todas as requests autenticadas
- [ ] 401 → refresh token → retry 1x; falha → logout
- [ ] Header \`X-Tenant-ID\` obrigatório nas rotas protegidas
- [ ] Secure storage (mobile) / storage seguro (web)
- [ ] Logout automático em 403 de tenant inválido

## Aceite
- Refresh silencioso sem relogar
- Trocar Tenant-ID manualmente → 403 tratado
- Token não fica em plain text inseguro

## Labels
P0 segurança — base para todo o operacional.
" "front,security,P0" "$FRONT_MS"

create_issue "$FRONT_REPO" \
"[Front] #27 Notificação realtime — SSE + som de novo pedido" \
"## User story
Como operador, quero ouvir um alerta quando chegar pedido novo.

## Solução (depende back SSE)
- EventSource em \`/api/v1/pedidos/stream\` (ou path que o back definir)
- \`new_order.mp3\` + Notification API + badge
- Reconexão automática

## Tarefas
- [ ] RealtimeService (connect / reconnect / dispose)
- [ ] Som + notificação (web + mobile capabilities)
- [ ] Atualizar lista/kanban sem F5
- [ ] Toggle mutar som

## Aceite
- Pedido novo reflete em < few seconds com som (quando SSE existir)
" "front,realtime,P1" "$FRONT_MS"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✓ Issues criadas"
echo "  FRONT: $FRONT_REPO  milestone: $FRONT_MILESTONE_TITLE (#$FRONT_MS)"
echo "  BACK:  $BACK_REPO   milestone: $BACK_MILESTONE_TITLE (#$BACK_MS)"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Próximo: priorizar P0 back (status+motivo, pagamento) e P0 front (modal #26 + kanban)."
echo "Branch sugerida front: feature/pedidos-modal-detalhe a partir de dev"
