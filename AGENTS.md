# AGENTS.md

## Visão geral

Este repositório é um app Flutter para dashboard de conversão de conversas do WhatsApp em compras (Conversation Commerce). O projeto usa arquitetura em camadas com foco em UI, providers, serviços e repositórios.

## Estrutura principal

- [lib/main.dart](lib/main.dart): bootstrap da aplicação, inicialização de storage e registro de providers.
- [lib/presentation](lib/presentation): telas, widgets e providers do app.
- [lib/data](lib/data): serviços HTTP, modelos, repositórios e armazenamento local.
- [lib/domain](lib/domain): entidades e casos de uso da regra de negócio.
- [pubspec.yaml](pubspec.yaml): dependências e configuração do Flutter.
- [README.md](README.md): documentação inicial do projeto.

## Fluxo de desenvolvimento

### Comandos úteis

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- `dart run build_runner build --delete-conflicting-outputs` quando houver mudanças em modelos Hive ou serialização JSON

### Padrões do projeto

- Use `provider` e `ChangeNotifier` para estado da UI.
- Evite colocar lógica de negócio diretamente em widgets; prefira providers e repositórios.
- Preserve a organização por camadas e os barrel exports existentes em:
  - [lib/data/services/services.dart](lib/data/services/services.dart)
  - [lib/data/repositories/repositories.dart](lib/data/repositories/repositories.dart)
  - [lib/presentation/providers/providers.dart](lib/presentation/providers/providers.dart)
  - [lib/presentation/pages/pages.dart](lib/presentation/pages/pages.dart)
- Siga o padrão de nomes atual: arquivos de tela terminam em `_page.dart`, providers em `*_provider.dart` e serviços em `*_service.dart`.
- Para modelos, mantenha a convenção de serialização já usada por `json_serializable` e `hive`.
- Quando novas telas forem adicionadas, prefira seguir a estrutura de páginas já existente dentro de `lib/presentation/pages/`.

## Arquitetura de dados

- `lib/data/services`: clientes HTTP e integrações externas.
- `lib/data/repositories`: abstração do acesso a dados e regras de persistência.
- `lib/data/models`: modelos de dados usados pela aplicação.
- `lib/presentation/providers`: gerência de estado e ações do usuário.

## Observações importantes

- O app já inicializa `LocalStorage` em [lib/main.dart](lib/main.dart); mantenha essa etapa ao alterar a inicialização.
- O registro de dependências é feito com `MultiProvider` em [lib/main.dart](lib/main.dart); novos serviços e repositórios devem seguir esse padrão.
- Não introduza padrões de estado alternativos sem necessidade, como bloc/cubit, quando a base do projeto já usa `provider`.
- Antes de alterar modelos, verifique se há geração de código e se os arquivos gerados precisam ser atualizados.

## Documentação relevante

- [README.md](README.md)
- [pubspec.yaml](pubspec.yaml)
- [lib/main.dart](lib/main.dart)
- [lib/presentation/providers/auth_provider.dart](lib/presentation/providers/auth_provider.dart)

## UX
Ver `docs/ux-patterns.md` (modal, quick edit, Criar/Salvar).
