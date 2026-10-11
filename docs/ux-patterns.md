# Padrao de tela OpenERP

- Ver detalhe: modal (web dialog / mobile sheet).
- Editar campo existente: salva na hora + `showSavedSnack` (1,5s, sem dialog).
- Criar registro: botao Criar ou Salvar.
- Web e mobile usam o mesmo fluxo.

Helper: `lib/core/helpers/snack_helper.dart` (`showSavedSnack`).
Nao usar `AlertDialog` de sucesso depois de PATCH.
