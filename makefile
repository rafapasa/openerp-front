# ============================================================
# Makefile para front-openerp
# Projeto Flutter - Dashboard Conversation Commerce
# ============================================================

PROJECT_NAME = front_openerp
FLUTTER ?= flutter
DART ?= dart
PUB = $(FLUTTER) pub
GIT = git
MSG ?= "Atualização do projeto $(PROJECT_NAME)"
COMPOSE_WEB_TESTE := docker-compose.web.teste.yml

# Compile-time Flutter (String.fromEnvironment). Nao e env do container.
API_BASE_URL_PROD ?= https://mcp-server.etoolstec.com.br/api/v1
API_BASE_URL_DEV  ?= https://teste.b.etoolstec.com.br/api/v1
DART_DEFINE_PROD = --dart-define=ENVIRONMENT=prod --dart-define=API_BASE_URL=$(API_BASE_URL_PROD)
DART_DEFINE_DEV  = --dart-define=ENVIRONMENT=dev --dart-define=API_BASE_URL=$(API_BASE_URL_DEV)

GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
RED = \033[0;31m
NC = \033[0m

help: ## Mostra esta ajuda
	@echo "$(BLUE)📋 Comandos disponíveis para $(PROJECT_NAME)$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

run: ## Rodar em todas as plataformas
	$(FLUTTER) run

run-web: ## Rodar no Chrome
	$(FLUTTER) run -d chrome $(DART_DEFINE_DEV)

run-web-ssh: ## Rodar web server exposto na rede
	$(FLUTTER) run -d web-server --web-hostname 0.0.0.0 --web-port 8080

run-linux: ## Rodar no Linux Desktop
	$(FLUTTER) run -d linux

run-android: ## Rodar no Android
	$(FLUTTER) run -d android

run-ios: ## Rodar no iOS
	$(FLUTTER) run -d ios

run-profile: ## Rodar em modo profile
	$(FLUTTER) run --profile

run-release: ## Rodar em modo release
	$(FLUTTER) run --release

build: build-web build-apk ## Build para todas as plataformas

build-web: ## Build para Web (release)
	$(FLUTTER) build web --release --no-wasm-dry-run $(DART_DEFINE_PROD)

build-apk: ## Build APK para Android
	$(FLUTTER) build apk --release

build-appbundle: ## Build App Bundle para Android
	$(FLUTTER) build appbundle --release

build-linux: ## Build para Linux Desktop
	$(FLUTTER) build linux --release

clean: ## Limpar arquivos temporários
	$(FLUTTER) clean

clean-all: clean ## Limpar tudo (incluindo cache do pub)
	rm -rf .dart_tool/ build/ pubspec.lock
	$(FLUTTER) pub get

deps: ## Instalar dependências
	$(PUB) get

deps-upgrade: ## Atualizar dependências
	$(PUB) upgrade --major-versions

deps-outdated: ## Verificar dependências desatualizadas
	$(PUB) outdated

analyze: ## Analisar código
	$(FLUTTER) analyze

test: ## Executar testes
	$(FLUTTER) test

test-coverage: ## Executar testes com cobertura
	$(FLUTTER) test --coverage

format: ## Formatar código
	$(DART) format lib/

dev: clean deps run-web ## Setup completo

watch: ## Rodar em modo watch
	$(FLUTTER) run

gen: ## Gerar arquivos (build_runner)
	$(DART) run build_runner build --delete-conflicting-outputs

gen-watch: ## Gerar arquivos em modo watch
	$(DART) run build_runner watch --delete-conflicting-outputs

serve: build-web ## Servir build web localmente
	cd build/web && python3 -m http.server 8080

setup: ## Configurar projeto do zero
	$(MAKE) clean
	$(MAKE) deps
	$(FLUTTER) doctor
	$(MAKE) analyze
	@echo "$(GREEN)🎉 Projeto configurado!$(NC)"

env: ## Mostrar versões
	$(FLUTTER) --version

logs: ## Logs do Flutter
	$(FLUTTER) logs

pub-cache: ## Limpar cache do pub
	$(PUB) cache repair

release: build-web build-apk build-linux ## Build de release completo
	@echo "$(GREEN)🎉 Builds geradas!$(NC)"

git-up: ## Add + commit + push
	$(GIT) add .
	$(GIT) commit -m ${MSG}
	$(GIT) push origin main

git-status: ## Status do git
	git status -sb && git diff --stat

git-add: ## Adicionar todos os arquivos
	git add -A && git status -sb

git-commit: ## Commit
ifndef MSG
	$(error Use: make git-commit MSG='tipo: mensagem')
endif
	git add -A
	git commit -m "$(MSG)"

git-push: ## Push
	git push -u origin HEAD

git-ciclo: ## Volta o worktree para ciclo (nao usa main)
	git stash push -u -m "wip-ciclo" -- lib/presentation/pages/produtos/uso_edit_dialog.dart lib/presentation/pages/produtos/uso_nn_combo.dart makefile || true
	git checkout ciclo
	git stash pop || true
	git status -sb

git-branch-6: ## Criar branch front-6
	git checkout -B front-6

git-restore-dash: ## Restaurar dashboard
	git checkout -- lib/presentation/pages/dashboard/dashboard_page.dart

DOCKER_USERNAME ?= rafapasa
IMAGE_TAG       ?= latest
WEB_IMAGE       := $(DOCKER_USERNAME)/openerp-web
DOCKERFILE_WEB  := Dockerfile.web
COMPOSE_WEB     := docker-compose.web.yml
NO_CACHE        ?= --no-cache

login: ## docker login no Hub
	docker login -u $(DOCKER_USERNAME)

build-push: ## Flutter build web + docker build ARM64 + push
ifeq ($(IMAGE_TAG),latest)
	$(error Use: make build-push IMAGE_TAG=0.1.0 — não pode buildar só latest)
endif
	@echo "🌐 flutter build web --release"
	$(FLUTTER) build web --release --no-wasm-dry-run $(DART_DEFINE_PROD)
	@test -f build/web/index.html || (echo "❌ falhou: build/web/index.html"; exit 1)
	@echo "🐳 Build ARM64 $(WEB_IMAGE):$(IMAGE_TAG) + latest"
	DOCKER_BUILDKIT=1 docker build $(NO_CACHE) \
		--platform linux/arm64 \
		-f $(DOCKERFILE_WEB) \
		-t $(WEB_IMAGE):$(IMAGE_TAG) \
		-t $(WEB_IMAGE):latest \
		.
	docker push $(WEB_IMAGE):$(IMAGE_TAG)
	docker push $(WEB_IMAGE):latest
	@echo "✅ $(WEB_IMAGE):$(IMAGE_TAG) + latest (linux/arm64) no Hub"

deploy: ## Sobe openerp-web na mcp-network
	@echo "🚀 Deploy $(WEB_IMAGE):$(IMAGE_TAG) → openerp.etoolstec.com.br"
	docker network create mcp-network || true
	IMAGE_TAG=$(IMAGE_TAG) DOCKER_USERNAME=$(DOCKER_USERNAME) docker compose -f $(COMPOSE_WEB) pull openerp-web
	IMAGE_TAG=$(IMAGE_TAG) DOCKER_USERNAME=$(DOCKER_USERNAME) docker compose -f $(COMPOSE_WEB) up -d --pull always --no-deps openerp-web
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep openerp-web || true
	@echo "✅ openerp-web no ar"


.PHONY: build-push-t
build-push-t: ## Flutter build web (API teste) + docker ARM64 + push :test
	@echo "🌐 flutter build web --release API=$(API_BASE_URL_DEV)"
	$(FLUTTER) build web --release --no-wasm-dry-run $(DART_DEFINE_DEV)
	@test -f build/web/index.html || (echo "❌ falhou: build/web/index.html"; exit 1)
	@echo "🐳 Build ARM64 $(WEB_IMAGE):test"
	DOCKER_BUILDKIT=1 docker build $(NO_CACHE) \
		--platform linux/arm64 \
		-f $(DOCKERFILE_WEB) \
		-t $(WEB_IMAGE):test \
		.
	docker push $(WEB_IMAGE):test
	@echo "✅ $(WEB_IMAGE):test enviado (API $(API_BASE_URL_DEV))"

.PHONY: deploy-t
deploy-t: ## Sobe openerp-web-teste na mcp-network (porta 8083)
	@echo "🚀 Deploy $(WEB_IMAGE):test (API $(API_BASE_URL_DEV))"
	IMAGE_TAG=test DOCKER_USERNAME=$(DOCKER_USERNAME) WEB_PORT=8083 \
		docker compose -f $(COMPOSE_WEB_TESTE) pull openerp-web-teste
	IMAGE_TAG=test DOCKER_USERNAME=$(DOCKER_USERNAME) WEB_PORT=8083 \
		docker compose -f $(COMPOSE_WEB_TESTE) up -d --pull always --no-deps openerp-web-teste
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep openerp-web-teste || true
	@echo "✅ openerp-web-teste no ar (host:8083 → nginx :80)"

logs-web-teste: ## Logs do container de teste
	docker logs -f openerp-web-teste --tail=100

logs-web: ## Logs do container
	docker logs -f openerp-web --tail=100

.PHONY: help run run-web run-web-ssh run-linux run-android run-ios run-profile run-release \
        build build-web build-apk build-appbundle build-linux \
        clean clean-all deps deps-upgrade deps-outdated \
        analyze test test-coverage format \
        dev watch gen gen-watch serve \
        setup env logs pub-cache release \
        git-up git-status git-add git-commit git-push git-branch-6 git-restore-dash \
        login build-push deploy logs-web \
        build-push-t deploy-t logs-web-teste
probe-emp:
	ls lib/presentation/pages | head
	find lib -iname '*empresa*' -o -iname '*tenant*' | head -40


test-llm-tab:
	export PATH="$$HOME/flutter/bin:$$PATH"; flutter test test/tenant_llm_config_test.dart
	export PATH="$$HOME/flutter/bin:$$PATH"; dart analyze lib/data/models/tenant_llm_config.dart lib/data/models/tenant_model.dart lib/presentation/pages/tenants/tenant_llm_tab.dart lib/presentation/pages/tenants/tenant_detalhe_modal.dart

commit-llm-tab:
	export PATH="$$HOME/flutter/bin:$$PATH"; dart analyze lib/data/services/tenant_service.dart lib/data/repositories/tenant_repository.dart lib/presentation/providers/tenant_provider.dart
	git add lib/data/models/tenant_llm_config.dart lib/data/models/tenant_model.dart lib/data/services/tenant_service.dart lib/data/repositories/tenant_repository.dart lib/presentation/providers/tenant_provider.dart lib/presentation/pages/tenants/tenant_llm_tab.dart lib/presentation/pages/tenants/tenant_detalhe_modal.dart test/tenant_llm_config_test.dart
	git checkout -- makefile Makefile || true
	git commit -m "feat(tenants): aba LLM no modal de empresa (#31)"
	git push origin ciclo
