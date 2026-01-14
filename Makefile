## ==============================================================================
# ORQUESTRADOR DE ARQUITECTURA - BASELINE ESTÁVEL (UBUNTU)
# ==============================================================================
# REGRAS: ARQUITECTURA IMUTÁVEL. NÃO MOVER NEM REMOVER FICHEIROS EXISTENTES.
# ESTE FICHEIRO GERE O CICLO DE VIDA LOCAL E A CONSTRUÇÃO DE ARTEFACTOS DOCKER.
# NÃO É PERMITIDA A ALTERAÇÃO E/OU REMOÇÃO DA INFORMAÇÃO JÁ EXISTENTE DESTE FICHEIRO. 
# APENAS PODERÁ ACRESCENTADA AO MESMO.

# ==============================================================================
# 1Variáveis e Configurações do Projeto
# ==============================================================================
PYTHON = .venv/bin/python3
PIP = .venv/bin/pip

# Definição do Ambiente (Default: local)
ENV ?= local
REPORTS_BASE = reports
REPORTS_DIR = $(REPORTS_BASE)/$(ENV)

# Comandos de sistema para o diagnóstico
CURL       = curl -s -f
NC         = nc -z localhost

# --- Configurações de Segurança 
# O operador ?= lê a variável diretamente da memória se ela já existir.
# É a forma correta de receber segredos injetados pelo GitHub Actions.
GRAFANA_USER     ?= $(GRAFANA_USER)
GRAFANA_PASS     ?= $(GRAFANA_PASS)
DOCKERHUB_USER   ?= $(DOCKERHUB_USER)
DOCKERHUB_TOKEN  ?= $(DOCKERHUB_TOKEN)

# Variável de Controle: Bloqueia o push localmente por design.
# No GitHub Actions, o runner passa isto como 'true'.
GITHUB_ACTIONS ?= false

# --- Metadados do Docker Hub (Públicos) ---
TAG             ?= latest

# Nomes das imagens para cada microserviço
IMAGE_USERS      = users-service
IMAGE_PRODUCTS   = products-service

# URLs completas para o Docker Hub
URL_USERS        = $(DOCKERHUB_USER)/$(IMAGE_USERS):$(TAG)
URL_PRODUCTS     = $(DOCKERHUB_USER)/$(IMAGE_PRODUCTS):$(TAG)

# Lógica de Comando de Execução Baseada no Ambiente
ifeq ($(ENV), docker)
    # No Docker, usamos o docker compose exec para rodar os comandos no container
    RUN_CMD = docker compose exec -T users-service python3 -m
else
    # No ambiente local, usamos o python do ambiente virtual (.venv)
    RUN_CMD = $(PYTHON) -m
endif

# URLs e Portas da Stack de Observabilidade
GRAFANA_PORT= 3000
PROMETHEUS_PORT= 9090
LOKI_PORT= 3100
TEMPO_PORT= 3200
DASHBOARD_URL= http://localhost:$(GRAFANA_PORT)/d/projeto_final_obs

# Exportação do PYTHONPATH para garantir que o Python resolve o pacote 'app'
export PYTHONPATH := $(shell pwd)

# NOVO TARGET PARA GARANTIR VISIBILIDADE
fix-perms:
	mkdir -p $(REPORTS_DIR)
	chmod -R 777 reports 2>/dev/null || true

install:
	@echo "--- [INSTALL] Criando ambiente virtual ---"
	python3 -m venv .venv
	$(PIP) install --upgrade "pip>=25.2"
	@if [ -f "app/users/requirements.txt" ]; then $(PIP) install -r app/users/requirements.txt; fi
	@if [ -f "app/products/requirements.txt" ]; then $(PIP) install -r app/products/requirements.txt; fi
	@if [ -f "requirements.dev" ]; then $(PIP) install -r requirements.dev; fi
	@mkdir -p $(REPORTS_DIR)
	$(MAKE) fix-perms
	@echo "--- [OK] Ambiente configurado. Relatórios em: $(REPORTS_DIR) ---"


# ==============================================================================
# 2. Qualidade e Segurança (Adaptados para RUN_CMD)
# ==============================================================================

format:
	@echo "--- [FORMAT] Executando Black no ambiente $(ENV) ---"
	$(RUN_CMD) black app/ tests/
	$(MAKE) fix-perms
	@echo "All done! ✨ 🍰 ✨"

lint:
	@echo "--- [LINT] Executando Flake8 no ambiente $(ENV) ---"
	@mkdir -p $(REPORTS_DIR)
	$(RUN_CMD) flake8 app/ tests/ --max-line-length=120 > $(REPORTS_DIR)/flake8_report.txt 2>&1 || true
	$(MAKE) fix-perms

security: bandit safety

bandit:
	@echo "--- [SECURITY] Executando Bandit no ambiente $(ENV) ---"
	@mkdir -p $(REPORTS_DIR)
	$(RUN_CMD) bandit -r app/ -ll > $(REPORTS_DIR)/bandit_report.txt 2>&1 || true
	$(MAKE) fix-perms

safety:
	@echo "--- [SECURITY] Executando Safety Check no ambiente $(ENV) ---"
	@mkdir -p $(REPORTS_DIR)
	$(RUN_CMD) safety check --full-report > $(REPORTS_DIR)/safety_report.txt 2>&1 || true
	$(MAKE) fix-perms

trivy-scan:
	@echo "--- [TRIVY] Garantindo acesso ao Docker Socket ---"
	-sudo chmod 666 /var/run/docker.sock
	@mkdir -p $(REPORTS_DIR)

	@echo "--- [TRIVY] Construindo imagens via caminhos diretos ---"
	@# Ajustei os caminhos para refletir o que testaste manualmente
	docker build -t users-service:latest -f ./app/users/Dockerfile.users . || exit 1
	docker build -t products-service:latest -f ./app/products/Dockerfile.products . || exit 1

	@echo "--- [TRIVY] Exportando imagens para TAR ---"
	docker save users-service:latest -o $(REPORTS_DIR)/users_temp.tar
	docker save products-service:latest -o $(REPORTS_DIR)/products_temp.tar

	@echo "--- [TRIVY] Iniciando scan de segurança ---"
	trivy image --severity HIGH,CRITICAL --exit-code 1 --input $(REPORTS_DIR)/users_temp.tar > $(REPORTS_DIR)/trivy_users_report.txt 2>&1 || \
		(echo "❌ Vulnerabilidades críticas encontradas! Verifique os relatórios."; rm -f $(REPORTS_DIR)/*.tar; exit 1)
	
	trivy image --severity HIGH,CRITICAL --exit-code 1 --input $(REPORTS_DIR)/products_temp.tar > $(REPORTS_DIR)/trivy_products_report.txt 2>&1 || \
		(echo "❌ Vulnerabilidades críticas encontradas! Verifique os relatórios."; rm -f $(REPORTS_DIR)/*.tar; exit 1)

	@echo "--- [TRIVY] Limpeza de temporários ---"
	rm -f $(REPORTS_DIR)/*.tar
	$(MAKE) fix-perms
	@echo "✅ Scan concluído com sucesso."
	
# ==============================================================================
# 3. Orquestrador run-local e Prova de Funcionalidade
# ==============================================================================

run-local: format lint bandit safety
	@mkdir -p $(REPORTS_DIR)
	@# Limpeza de portas antes de iniciar
	-@fuser -k 5000/tcp 2>/dev/null || true
	-@fuser -k 5001/tcp 2>/dev/null || true
	@# Execução em background
	@$(PYTHON) -m app.users.users > $(REPORTS_DIR)/users_service.log 2>&1 & echo $$! > $(REPORTS_DIR)/users.pid
	@$(PYTHON) -m app.products.products > $(REPORTS_DIR)/products_service.log 2>&1 & echo $$! > $(REPORTS_DIR)/products.pid
	@echo "Aguardando 10s para estabilização dos serviços..."
	@sleep 10
	@echo "Injetando carga real... Este script gera 50 chamadas sequenciais"
	@echo "A gerar 50 requisições de teste. Verifique o Grafana (http://localhost:3000)."
	@# CICLO FOR INTEGRADO (As barras invertidas \ são obrigatórias para manter o contexto do loop)
	@for i in $$(seq 1 25); do \
		curl -s -f http://localhost:5000/users > /dev/null || { echo "❌ Erro no Users ($$i)"; exit 1; }; \
		curl -s -f http://localhost:5001/products > /dev/null || { echo "❌ Erro no Products ($$i)"; exit 1; }; \
		curl -s -f http://localhost:5001/e2e/products-with-users > /dev/null || { echo "❌ Erro no E2E ($$i)"; exit 1; }; \
		echo "  - Ciclo $$i/25: OK"; \
		sleep 0.1; \
	done
	@echo "Geração de tráfego concluída via Makefile."
	@echo "--- [TESTS] Executando bateria de testes funcionais ---"
	@export PYTHONPATH=$(PWD) && \
	 export USERS_SERVICE_URL=http://localhost:5000 && \
	 export PRODUCTS_SERVICE_URL=http://localhost:5001 && \
	 $(PYTHON) -m pytest -v tests/
	$(MAKE) fix-perms


	@echo "\n===================================================================="
	@echo "        PROVA DE FUNCIONALIDADE DA STACK DE OBSERVABILIDADE"
	@echo "===================================================================="
	@echo "1. AMOSTRA DE MÉTRICAS (Prometheus /metrics):"
	@curl -s http://localhost:5000/metrics | grep -E "python_info|process_cpu_seconds_total" | head -n 5 || echo "Aviso: Métricas offline."
	@echo "\n2. AMOSTRA DE LOGS ESTRUTURADOS E TRACING (JSON):"
	@tail -n 3 $(REPORTS_DIR)/users_service.log
	@echo "\n3. VALIDAÇÃO DE CONEXÃO DOS ENDPOINTS:"
	@curl -s -o /dev/null -w "  [OK] Users Metrics Endpoint\n" http://localhost:5000/metrics || echo "  [ERRO] Users Offline"
	@curl -s -o /dev/null -w "  [OK] Products Metrics Endpoint\n" http://localhost:5001/metrics || echo "  [ERRO] Products Offline"
	@echo "===================================================================="
	@echo "\n--- [DONE] Validação de Observabilidade concluída ---"
	@echo "\n--- [BACKUP] Copiando relatórios para histórico $(REPORTS_LOCAL) ---"
	#@# Usamos CP para manter a raiz funcional para o Grafana/Prometheus
	#@cp $(REPORTS_DIR)/*.txt $(REPORTS_DIR)/*.log $(REPORTS_LOCAL)/ 2>/dev/null || true
	#@echo "Serviços ativos. Monitorização em tempo real disponível."


tests:
	@echo "--- [TESTS] Executando bateria de testes unitários ---"
	@export PYTHONPATH=$(shell pwd) && \
	$(PYTHON) -m pytest -v tests/




# ==============================================================================
# 4. Gestão de Processos e Limpeza
# ==============================================================================

stop-local:
	@echo "--- [STOP] Terminando processos Python e libertando portas ---"
	-@if [ -f $(REPORTS_DIR)/users.pid ]; then kill -9 $$(cat $(REPORTS_DIR)/users.pid) 2>/dev/null; rm $(REPORTS_DIR)/users.pid; fi
	-@if [ -f $(REPORTS_DIR)/products.pid ]; then kill -9 $$(cat $(REPORTS_DIR)/products.pid) 2>/dev/null; rm $(REPORTS_DIR)/products.pid; fi
	-@fuser -k 5000/tcp 2>/dev/null || true
	-@fuser -k 5001/tcp 2>/dev/null || true
	$(MAKE) fix-perms
	@echo "--- [OK] Processos encerrados ---"


clean-reports:
	@echo "A limpar apenas a pasta de relatórios..."
	rm -f ./reports/local/*.txt
	rm -f ./reports/local/*.log
	rm -f ./reports/local/*.pid
	rm -f ./reports/local/*.tar


clean-interactive:
	@echo "Qual diretório de relatórios deseja limpar? [1) Local 2) Docker 3) Ambos 4) Cancelar]"
	@read choice; \
	if [ "$$choice" = "1" ]; then rm -rf $(REPORTS_LOCAL)/*; \
	elif [ "$$choice" = "2" ]; then rm -rf $(REPORTS_DOCKER)/*; \
	elif [ "$$choice" = "3" ]; then rm -rf $(REPORTS_DIR)/*; fi

clean:
	@echo "--- [CLEAN] Reset Total do Ambiente ---" 
	rm -rf $(REPORTS_BASE) .venv .pytest_cache logs
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

all: install run-local

# ==============================================================================
# 5. Extensão para Docker V2 e Nuvem (Secção Original Atualizada)
# ==============================================================================

.PHONY: docker-build docker-up docker-down docker-status docker-logs docker-debug docker-run

# Nova regra para limpeza específica de Docker

docker-clean:
	@echo "--- [DOCKER-CLEAN] Removendo contentores e imagens do projeto ---"
	-docker-compose down --rmi all --volumes --remove-orphans 2>/dev/null || true
	-docker rmi users-service:latest products-service:latest --force 2>/dev/null || true
	@echo "--- [DOCKER-CLEAN] Limpando imagens intermédias (build cache) ---"
	-docker image prune -f
	@echo "--- [OK] Ambiente Docker limpo. Próximo build será do zero. ---"


docker-build:
	@echo "--- [DOCKER-V2] Construindo imagens SEM CACHE (Garante código novo) ---"
	docker build --no-cache -f $$(find . -maxdepth 3 -iname "*Docker*user*" | head -n 1) -t users-service:latest .
	docker build --no-cache -f $$(find . -maxdepth 3 -iname "*Docker*product*" | head -n 1) -t products-service:latest .
	@echo "--- [OK] Imagens prontas para Docker V2 ---"

docker-up: 
	@echo "--- [DOCKER] A levantar serviços existentes (Sem Build) ---"
	docker compose up -d
	@echo "A aguardar estabilização (5s)..."
	@sleep 5
	@$(MAKE) --no-print-directory docker-status

docker-down:
	@echo "--- [DOCKER-V2] Removendo infraestrutura e contentores ---"
	docker compose down

docker-status:
	@echo "--- [DOCKER-V2] Verificando estado da Nuvem Local ---"
	docker compose ps

docker-logs:
	@echo "--- [DOCKER-V2] Exibindo logs recentes ---"
	docker compose logs --tail=50 products-service

docker-debug:
	@echo "--- [DEBUG] Capturando o erro 500 exato do serviço de Produtos ---"
	@curl -s http://localhost:5001/e2e/products-with-users || true
	@echo "\n--- [TRACEBACK DO CONTENTOR] ---"
	@docker logs projecto_final-products-service-1 --tail 30

debug-network:
	@echo "--- [DEBUG] Verificando Resolução de Localhost ---"
	@ping -c 1 localhost | head -n 1
	@echo "\n--- [DEBUG] Verificando Portos Abertos no Host ---"
	@netstat -tuln | grep -E "$(LOKI_PORT)|$(TEMPO_PORT)" || echo "Portos não encontrados no netstat!"
	
	@echo "\n--- [DEBUG] Testando conectividade direta (IPv4 vs IPv6) ---"
	@echo "Tentando IPv4 (127.0.0.1):"
	@curl -4 -s -I http://127.0.0.1:$(LOKI_PORT)/ready | head -n 1 || echo "IPv4 Falhou"
	@echo "Tentando IPv6 (::1):"
	@curl -6 -s -I http://localhost:$(LOKI_PORT)/ready | head -n 1 || echo "IPv6 Falhou"

docker-run:

	@echo "--- [DOCKER-RUN] Iniciando ciclo exclusivo em Contentores ---"
	@# Garantir que a pasta de relatórios para o docker existe antes de iniciar
	@mkdir -p reports/docker
	@chmod -R 777 reports/docker 2>/dev/null || true

	@# 1. Garantir infraestrutura
	$(MAKE) docker-up
	
	@echo "--- [SYNC] Sincronizando Stack (45s) ---"
	@sleep 45
	
	@echo "--- [QUALITY] Executando Linter e Segurança via Docker ---"
	@# Forçamos o uso do comando Docker para não correr localmente
	docker compose exec -T users-service python3 -m black app/ tests/ || exit 1
	docker compose exec -T users-service python3 -m flake8 app/ tests/ --max-line-length=120 > reports/docker/flake8_report.txt 2>&1 || exit1
	docker compose exec -T users-service python3 -m bandit -r app/ -ll > reports/docker/bandit_report.txt 2>&1 || exit 1
	docker compose exec -T users-service python3 -m safety check --full-report > reports/docker/safety_report.txt 2>&1 || exit 1
	
	@echo "--- [TESTS] Executando testes funcionais via Rede Interna Docker ---"
	@# INJEÇÃO CRÍTICA: Passamos as URLs dos serviços como nomes de rede do Docker
	docker compose exec -T \
		-e PRODUCTS_SERVICE_URL=http://products-service:5001 \
		-e USERS_SERVICE_URL=http://users-service:5000 \
		users-service python3 -m pytest -v tests/ | tee reports/docker/tests_report.txt; \
	  if [ $${PIPESTATUS[0]} -ne 0 ]; then echo "❌ Testes falharam no Docker!"; exit 1; fi

	@echo "--- [STATUS] Ciclo Docker concluído com sucesso ---"
	$(MAKE) docker-status
	@echo "--- [DONE] Ciclo concluído. Relatórios em: reports/docker/ ---"

docker-trivy-run:
	@echo "--- [TRIVY-RUN] Executando scan de vulnerabilidades direto ---"
	@$(MAKE) trivy-scan ENV=docker
	@echo "--- [SYNC] Copiando relatórios para a pasta de Staging ---"
	@cp $(REPORTS_DIR)/trivy_users_report.txt $(REPORTS_DOCKER)/ 2>/dev/null || true
	@cp $(REPORTS_DIR)/trivy_products_report.txt $(REPORTS_DOCKER)/ 2>/dev/null || true
	@echo "--- [OK] Relatórios de segurança consolidados em $(REPORTS_DOCKER)/ ---"

docker-dashboard:
	@echo "\n===================================================================="
	@echo "    PROVA DE FUNCIONALIDADE: DIAGNÓSTICO DE SAÚDE"
	@echo "===================================================================="
	@echo "--- [WAIT] Aguardando 40s para estabilização de serviços... ---"
	@sleep 40
	@echo "[STEP 1] Injetando carga real e validando Microserviços..."
	@for i in $$(seq 1 25); do \
		curl -s -f --connect-timeout 2 http://localhost:5000/users > /dev/null || { echo "❌ Erro no Users ($$i)"; exit 1; }; \
		curl -s -f --connect-timeout 2 http://localhost:5001/products > /dev/null || { echo "❌ Erro no Products ($$i)"; exit 1; }; \
		curl -s -f --connect-timeout 2 http://localhost:5001/e2e/products-with-users > /dev/null || { echo "❌ Erro no Fluxo E2E ($$i)"; exit 1; }; \
	done
	@echo "✅ Tráfego e Microserviços: OK"

	@echo "\n[STEP 2] PROMETHEUS (porta 9090):"
	@if curl -s -f http://localhost:9090/-/healthy > /dev/null; then \
		echo "  -> [OK] Prometheus está pronto."; \
	else \
		echo "  -> [FAIL] Prometheus inacessível."; exit 1; \
	fi

	@echo "\n[STEP 3] LOKI (porta 3100):"
	@if curl -s -f http://localhost:3100/ready > /dev/null; then \
		echo "  -> [OK] Loki Service: READY"; \
	else \
		echo "  -> [FAIL] Loki não respondeu READY."; exit 1; \
	fi

	@echo "\n[STEP 4] TEMPO (porta 3200):"
	@if curl -s -f http://localhost:3200/ready > /dev/null; then \
		echo "  -> [OK] Tempo Service: READY"; \
	else \
		echo "  -> [FAIL] Tempo inacessível via localhost:3200."; exit 1; \
	fi

	@echo "\n[STEP 5] OTEL COLLECTOR (porta 4317/4318):"
	@if nc -z localhost 4318; then \
		echo "  -> [OK] OTel Collector está a receber sinais."; \
	else \
		echo "  -> [FAIL] OTel Collector está offline."; exit 1; \
	fi

	@echo "\n[STEP 6] VALIDANDO ACESSO AO GRAFANA (Segurança):"
	@if [ -z "$(GRAFANA_USER)" ] || [ -z "$(GRAFANA_PASS)" ]; then \
		echo "  -> [FAIL] ERRO CRÍTICO: Credenciais ausentes"; exit 1; \
	else \
		if curl -s -f -u $(GRAFANA_USER):$(GRAFANA_PASS) http://localhost:3000/api/health > /dev/null; then \
			echo "  -> [OK] Autenticação Grafana: SUCESSO"; \
		else \
			echo "  -> [FAIL] Falha de autenticação no Grafana."; exit 1; \
		fi; \
	fi
	@echo "\n✅ [STAGING] Stack de Observabilidade 100% Funcional!"

	@echo "\n[INFO] ACESSO PARA DEMONSTRAÇÃO:"
	@echo "    Dashboard: $(DASHBOARD_URL)"
	@echo "    User:      $(GRAFANA_USER)"

docker-hub-upload:
	@echo "--- [CHECK] Verificando permissões para $(DOCKERHUB_USER) [Tag: $(TAG)] ---"
	@if [ "$(GITHUB_ACTIONS)" = "false" ]; then \
		echo "----------------------------------------------------------"; \
		echo "🛡️  SEGURANÇA: Upload local bloqueado."; \
		echo "O push para o Docker Hub deve ser feito via GitHub Actions."; \
		echo "Isto garante que a imagem passou por todos os testes de CI."; \
		echo "----------------------------------------------------------"; \
		exit 1; \
	fi
	@if [ -z "$(DOCKERHUB_TOKEN)" ]; then echo "❌ Erro: DOCKERHUB_TOKEN vazio."; exit 1; fi
	
	@echo "--- [AUTH] Autenticando no Docker Hub ---"
	@echo $(DOCKERHUB_TOKEN) | docker login -u $(DOCKERHUB_USER) --password-stdin
	
	@echo "--- [TAGGING] Preparando artefactos para a versão $(TAG) ---"
	# Aqui criamos as tags específicas para cada serviço antes do push
	docker tag users-service:latest $(URL_USERS)
	docker tag products-service:latest $(URL_PRODUCTS)
	
	@echo "--- [PUSH] Enviando imagens para o Registry ---"
	@echo "🚀 Enviando: $(URL_USERS)"
	docker push $(URL_USERS)
	
	@echo "🚀 Enviando: $(URL_PRODUCTS)"
	docker push $(URL_PRODUCTS)
	
	@docker logout
	@echo "--- [OK] Entrega da versão $(TAG) concluída! ---"
