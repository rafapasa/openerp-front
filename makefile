# ============================================================
# Makefile para front-openerp
# Projeto Flutter - Dashboard Conversation Commerce
# ============================================================

# Variáveis
PROJECT_NAME = front_openerp
FLUTTER = flutter
DART = dart
PUB = flutter pub
GIT = git
MSG ?= "Atualização do projeto $(PROJECT_NAME)"

# Cores para output
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
RED = \033[0;31m
NC = \033[0m # No Color

# ============================================================
# 📦 HELP - Tarefas disponíveis
# ============================================================
help: ## Mostra esta ajuda
	@echo "$(BLUE)📋 Comandos disponíveis para $(PROJECT_NAME)$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Exemplos:$(NC)"
	@echo "  make run-web       - Rodar no navegador"
	@echo "  make run-web-ssh   - Rodar web server exposto na rede (SSH)"
	@echo "  make build-apk     - Gerar APK para Android"
	@echo "  make clean         - Limpar projeto"

# ============================================================
# 🚀 EXECUÇÃO
# ============================================================

run: ## Rodar em todas as plataformas (web + desktop + mobile)
	@echo "$(BLUE)🚀 Rodando $(PROJECT_NAME)...$(NC)"
	$(FLUTTER) run

run-web: ## Rodar no navegador (Chrome)
	@echo "$(BLUE)🌐 Rodando no Chrome...$(NC)"
	$(FLUTTER) run -d chrome

run-web-ssh: ## Rodar web server exposto na rede (acesso via SSH)
	@echo "$(BLUE)🌐 Rodando web server em http://0.0.0.0:8080...$(NC)"
	$(FLUTTER) run -d web-server --web-hostname 0.0.0.0 --web-port 8080

run-linux: ## Rodar no Linux Desktop
	@echo "$(BLUE)🐧 Rodando no Linux Desktop...$(NC)"
	$(FLUTTER) run -d linux

run-android: ## Rodar no Android (emulador ou dispositivo)
	@echo "$(BLUE)📱 Rodando no Android...$(NC)"
	$(FLUTTER) run -d android

run-ios: ## Rodar no iOS (requer macOS)
	@echo "$(BLUE)🍎 Rodando no iOS...$(NC)"
	$(FLUTTER) run -d ios

run-profile: ## Rodar em modo profile (para análise de performance)
	@echo "$(BLUE)📊 Rodando em modo profile...$(NC)"
	$(FLUTTER) run --profile

run-release: ## Rodar em modo release (otimizado)
	@echo "$(BLUE)🚀 Rodando em modo release...$(NC)"
	$(FLUTTER) run --release

# ============================================================
# 🏗️ BUILD
# ============================================================

build: build-web build-apk ## Build para todas as plataformas

build-web: ## Build para Web (release)
	@echo "$(BLUE)🌐 Buildando para Web...$(NC)"
	$(FLUTTER) build web --release
	@echo "$(GREEN)✅ Build Web concluído!$(NC)"
	@echo "📁 Local: build/web/"

build-apk: ## Build APK para Android (release)
	@echo "$(BLUE)📱 Buildando APK para Android...$(NC)"
	$(FLUTTER) build apk --release
	@echo "$(GREEN)✅ APK concluído!$(NC)"
	@echo "📁 Local: build/app/outputs/flutter-apk/app-release.apk"

build-appbundle: ## Build App Bundle para Android (Google Play)
	@echo "$(BLUE)📱 Buildando App Bundle...$(NC)"
	$(FLUTTER) build appbundle --release
	@echo "$(GREEN)✅ App Bundle concluído!$(NC)"
	@echo "📁 Local: build/app/outputs/bundle/release/app-release.aab"

build-linux: ## Build para Linux Desktop
	@echo "$(BLUE)🐧 Buildando para Linux...$(NC)"
	$(FLUTTER) build linux --release
	@echo "$(GREEN)✅ Build Linux concluído!$(NC)"
	@echo "📁 Local: build/linux/x64/release/bundle/"

build-windows: ## Build para Windows Desktop
	@echo "$(BLUE)🪟 Buildando para Windows...$(NC)"
	$(FLUTTER) build windows --release
	@echo "$(GREEN)✅ Build Windows concluído!$(NC)"
	@echo "📁 Local: build/windows/x64/runner/Release/"

build-macos: ## Build para macOS Desktop
	@echo "$(BLUE)🍎 Buildando para macOS...$(NC)"
	$(FLUTTER) build macos --release
	@echo "$(GREEN)✅ Build macOS concluído!$(NC)"

# ============================================================
# 🧹 LIMPEZA
# ============================================================

clean: ## Limpar arquivos temporários e builds
	@echo "$(YELLOW)🧹 Limpando projeto...$(NC)"
	$(FLUTTER) clean
	@echo "$(GREEN)✅ Projeto limpo!$(NC)"

clean-all: clean ## Limpar tudo (incluindo cache do pub)
	@echo "$(YELLOW)🧹 Limpando cache do pub...$(NC)"
	rm -rf .dart_tool/
	rm -rf build/
	rm -rf pubspec.lock
	$(FLUTTER) pub get
	@echo "$(GREEN)✅ Tudo limpo!$(NC)"

# ============================================================
# 📦 DEPENDÊNCIAS
# ============================================================

deps: ## Instalar/atualizar dependências
	@echo "$(BLUE)📦 Instalando dependências...$(NC)"
	$(PUB) get
	@echo "$(GREEN)✅ Dependências instaladas!$(NC)"

deps-upgrade: ## Atualizar dependências para as últimas versões
	@echo "$(BLUE)📦 Atualizando dependências...$(NC)"
	$(PUB) upgrade --major-versions
	@echo "$(GREEN)✅ Dependências atualizadas!$(NC)"

deps-outdated: ## Verificar dependências desatualizadas
	@echo "$(BLUE)📊 Verificando dependências desatualizadas...$(NC)"
	$(PUB) outdated

# ============================================================
# 🔧 ANÁLISE E TESTES
# ============================================================

analyze: ## Analisar código (lint)
	@echo "$(BLUE)🔍 Analisando código...$(NC)"
	$(FLUTTER) analyze
	@echo "$(GREEN)✅ Análise concluída!$(NC)"

test: ## Executar testes
	@echo "$(BLUE)🧪 Executando testes...$(NC)"
	$(FLUTTER) test
	@echo "$(GREEN)✅ Testes concluídos!$(NC)"

test-coverage: ## Executar testes com cobertura
	@echo "$(BLUE)📊 Executando testes com cobertura...$(NC)"
	$(FLUTTER) test --coverage
	@echo "$(GREEN)✅ Cobertura gerada!$(NC)"
	@echo "📁 Local: coverage/"

format: ## Formatar código
	@echo "$(BLUE)🎨 Formatando código...$(NC)"
	$(DART) format lib/
	@echo "$(GREEN)✅ Código formatado!$(NC)"

# ============================================================
# 🛠️ DESENVOLVIMENTO
# ============================================================

dev: clean deps run-web ## Setup completo para desenvolvimento

watch: ## Rodar em modo watch (hot reload)
	@echo "$(BLUE)👀 Rodando em modo watch...$(NC)"
	$(FLUTTER) run

# ============================================================
# 📱 GERAR ARQUIVOS (se usar build_runner)
# ============================================================

gen: ## Gerar arquivos (build_runner)
	@echo "$(BLUE)⚙️  Gerando arquivos...$(NC)"
	$(DART) run build_runner build --delete-conflicting-outputs

gen-watch: ## Gerar arquivos em modo watch
	@echo "$(BLUE)👀 Gerando arquivos em watch...$(NC)"
	$(DART) run build_runner watch --delete-conflicting-outputs

# ============================================================
# 🗄️ SERVIDOR DE DESENVOLVIMENTO
# ============================================================

serve: build-web ## Servir build web localmente
	@echo "$(BLUE)🌐 Servindo build web...$(NC)"
	cd build/web && python3 -m http.server 8080
	@echo "$(GREEN)✅ Servidor rodando em http://localhost:8080$(NC)"

# ============================================================
# 🚀 INSTALAÇÃO DO PROJETO
# ============================================================

setup: ## Configurar projeto do zero
	@echo "$(BLUE)⚙️  Configurando projeto...$(NC)"
	@echo "$(GREEN)1/5$(NC) Limpando..."
	$(MAKE) clean
	@echo "$(GREEN)2/5$(NC) Instalando dependências..."
	$(MAKE) deps
	@echo "$(GREEN)3/5$(NC) Verificando flutter..."
	$(FLUTTER) doctor
	@echo "$(GREEN)4/5$(NC) Analisando código..."
	$(MAKE) analyze
	@echo "$(GREEN)5/5$(NC) Projeto pronto!"
	@echo ""
	@echo "$(GREEN)🎉 Projeto configurado com sucesso!$(NC)"
	@echo ""
	@echo "$(YELLOW)Próximos passos:$(NC)"
	@echo "  make run-web      - Rodar no navegador"
	@echo "  make build-apk    - Gerar APK"
	@echo "  make help         - Ver todos os comandos"

# ============================================================
# 🔐 VARIÁVEIS DE AMBIENTE
# ============================================================

env: ## Mostrar variáveis de ambiente do Flutter
	@echo "$(BLUE)📋 Variáveis de ambiente Flutter:$(NC)"
	$(FLUTTER) --version
	@echo ""
	$(FLUTTER) doctor -v | grep -E "(Android|Chrome|Linux|Connected)"

# ============================================================
# 📝 LOGS
# ============================================================

logs: ## Mostrar logs do Flutter
	@echo "$(BLUE)📝 Logs do Flutter:$(NC)"
	$(FLUTTER) logs

# ============================================================
# 🧪 PUB COMMANDS
# ============================================================

pub-cache: ## Limpar cache do pub
	@echo "$(YELLOW)🧹 Limpando cache do pub...$(NC)"
	$(PUB) cache repair
	@echo "$(GREEN)✅ Cache limpo!$(NC)"

# ============================================================
# 📦 RELEASE
# ============================================================

release: build-web build-apk build-linux ## Gerar todas as builds de release
	@echo "$(GREEN)🎉 Todas as builds geradas!$(NC)"
	@echo ""
	@echo "$(YELLOW)📁 Arquivos gerados:$(NC)"
	@echo "  Web: build/web/"
	@echo "  Android: build/app/outputs/flutter-apk/app-release.apk"
	@echo "  Linux: build/linux/x64/release/bundle/"

# ============================================================
# PHONY (evita conflitos com arquivos de mesmo nome)
# ============================================================
.PHONY: help run run-web run-web-ssh run-linux run-android run-ios run-profile run-release \
        build build-web build-apk build-appbundle build-linux build-windows build-macos \
        clean clean-all deps deps-upgrade deps-outdated \
        analyze test test-coverage format \
        dev watch gen gen-watch serve \
        setup env logs pub-cache release


# ============================================================
# 📦 GIT
# ============================================================

git-up: ## Add commit e push das alterações no git
	@echo "$(YELLOW)🧹 git add...$(NC)"
	$(GIT) add .
	@echo "$(YELLOW)🧹 git commit...$(NC)"
	$(GIT) commit -m ${MSG}
	@echo "$(YELLOW)🧹 git push...$(NC)"
	$(GIT) push origin main
	@echo "$(GREEN)✅ Alterações adicionadas ao git!$(NC)"


# ============================================================
# PHONY (evita conflitos com arquivos de mesmo nome)
# ============================================================
.PHONY: help run run-web run-web-ssh run-linux run-android run-ios run-profile run-release \
        build build-web build-apk build-appbundle build-linux build-windows build-macos \
        clean clean-all deps deps-upgrade deps-outdated \
        analyze test test-coverage format \
        dev watch gen gen-watch serve \
        setup env logs pub-cache release \
		git-up


# ============================================================
# DEPLOY OCI — openerp.etoolstec.com.br
# Mesmo modelo do back: build-push exige tag; deploy assume latest
# ============================================================

DOCKER_USERNAME := rafapasa
IMAGE_TAG       ?= latest
WEB_IMAGE       := $(DOCKER_USERNAME)/openerp-web
DOCKERFILE_WEB  := Dockerfile.web
COMPOSE_WEB     := docker-compose.web.yml
NO_CACHE        ?=

.PHONY: login build-push deploy logs-web

login: ## docker login no Hub
	docker login -u $(DOCKER_USERNAME)

build-push: ## flutter build web no host + image nginx linux/arm64 (IMAGE_TAG=x.y.z)
ifeq ($(IMAGE_TAG),latest)
	$(error Use: make build-push IMAGE_TAG=0.1.0 — não pode buildar só latest)
endif
	@echo "$(BLUE)🌐 flutter build web --release$(NC)"
	$(FLUTTER) build web --release --no-wasm-dry-run
	@test -f build/web/index.html || (echo "$(RED)falhou: build/web/index.html$(NC)"; exit 1)
	@echo "$(BLUE)🐳 Build ARM64 $(WEB_IMAGE):$(IMAGE_TAG) + latest$(NC)"
	DOCKER_BUILDKIT=1 docker build $(NO_CACHE) \
		--platform linux/arm64 \
		-f $(DOCKERFILE_WEB) \
		-t $(WEB_IMAGE):$(IMAGE_TAG) \
		-t $(WEB_IMAGE):latest \
		.
	docker push $(WEB_IMAGE):$(IMAGE_TAG)
	docker push $(WEB_IMAGE):latest
	@echo "$(GREEN)✅ $(WEB_IMAGE):$(IMAGE_TAG) + latest (linux/arm64) no Hub$(NC)"

deploy: ## Sobe openerp-web na mcp-network (IMAGE_TAG opcional, default latest)
	@echo "$(BLUE)🚀 Deploy $(WEB_IMAGE):$(IMAGE_TAG) → openerp.etoolstec.com.br$(NC)"
	docker network create mcp-network || true
	IMAGE_TAG=$(IMAGE_TAG) docker compose -f $(COMPOSE_WEB) pull openerp-web
	IMAGE_TAG=$(IMAGE_TAG) docker compose -f $(COMPOSE_WEB) up -d --pull always --no-deps openerp-web
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep openerp-web || true
	@echo "$(GREEN)✅ openerp-web no ar$(NC)"

logs-web: ## Logs do container openerp-web
	docker logs -f openerp-web --tail=100
