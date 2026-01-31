## ==============================================================================
# ORQUESTRADOR DE ARQUITECTURA - BASELINE ESTÁVEL (UBUNTU)
# ==============================================================================
# REGRAS: ARQUITECTURA IMUTÁVEL. NÃO MOVER NEM REMOVER FICHEIROS EXISTENTES.
# ESTE FICHEIRO GERE O CICLO DE VIDA LOCAL E A CONSTRUÇÃO DE ARTEFACTOS DOCKER.
# NÃO É PERMITIDA A ALTERAÇÃO E/OU REMOÇÃO DA INFORMAÇÃO JÁ EXISTENTE DESTE FICHEIRO. 
# APENAS PODERÁ ACRESCENTADA AO MESMO.

# ==============================================================================
# 1.Variáveis e Configurações do Projeto
# ==============================================================================
SHELL := /bin/bash
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
GRAFANA_USER     ?= (GRAFANA_USER)
GRAFANA_PASS     ?= (GRAFANA_PASS)
DOCKERHUB_USER   ?= (DOCKERHUB_USER)
DOCKERHUB_TOKEN  ?= (DOCKERHUB_TOKEN)

# Variável de Controle: Bloqueia o push localmente por design.
# No GitHub Actions, o runner passa isto como 'true'.
GITHUB_ACTIONS ?= false

# --- Metadados do Docker Hub (Públicos) ---
TYPE            ?= slim
TAG             ?= latest

# Lógica de sufixo para ficheiros
ifeq ($(TYPE),slim)
    DOCKER_SUFFIX :=
else
    DOCKER_SUFFIX := .$(TYPE)
endif

# Nomes das imagens e tags dinâmicas para cada microserviço
IMAGE_USERS      = users-service
IMAGE_PRODUCTS   = products-service
IMAGE_USERS_TAG    = $(IMAGE_USERS):$(TYPE)
IMAGE_PRODUCTS_TAG = $(IMAGE_PRODUCTS):$(TYPE)

# URLs completas para o Docker Hub
URL_USERS        = $(DOCKERHUB_USER)/$(IMAGE_USERS):$(TAG)-$(TYPE)
URL_PRODUCTS     = $(DOCKERHUB_USER)/$(IMAGE_PRODUCTS):$(TAG)-$(TYPE)

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
	@echo "--- [SECURITY] A gerar relatório para $(TYPE) ---"
	@mkdir -p $(REPORTS_DIR)
	
	# Criar e extrair o sistema de ficheiros
	-@docker rm -f temp_$(TYPE) 2>/dev/null
	@docker create --name temp_$(TYPE) users-service:$(TYPE)
	@mkdir -p $(REPORTS_DIR)/rootfs_$(TYPE)
	@sudo docker export temp_$(TYPE) | tar -C $(REPORTS_DIR)/rootfs_$(TYPE) -xf - 2>/dev/null || true
	
	# Executa o scan, gera o relatório em TXT e para o build se houver falhas
	trivy fs --severity HIGH,CRITICAL --exit-code 1 --format table \
		--output $(REPORTS_DIR)/trivy_$(TYPE).txt $(REPORTS_DIR)/rootfs_$(TYPE); \
	EXIT_CODE=$$?; \
	echo "--- [CLEANUP] Removendo pasta temporária ---"; \
	sudo rm -rf $(REPORTS_DIR)/rootfs_$(TYPE); \
	docker rm -f temp_$(TYPE) 2>/dev/null; \
	exit $$EXIT_CODE
	@echo "✅ Imagem $(TYPE) aprovada para produção."
	@echo "📊 Relatório disponível em: $(REPORTS_DIR)/trivy_report_$(TYPE).txt"
	
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
	-docker rmi $(IMAGE_USERS_TAG) $(IMAGE_PRODUCTS_TAG) --force 2>/dev/null || true
	@echo "--- [DOCKER-CLEAN] Limpando imagens intermédias (build cache) ---"
	-docker image prune -f
	@echo "--- [OK] Ambiente Docker limpo. Próximo build será do zero. ---"


# Usar Type vazio para imagem slim, alpine ou wolfi :

docker-build:
	@echo "--- [DOCKER-V2] Construindo imagens SEM CACHE para TYPE=$(TYPE)"
	docker build --no-cache -f app/users/Dockerfile.users -t $(IMAGE_USERS_TAG) .
	docker build --no-cache -f app/products/Dockerfile.products -t $(IMAGE_PRODUCTS_TAG) .
	@echo "--- [OK] Imagens prontas para Docker V2 ---"

docker-up: 
	@echo "--- [DOCKER] A levantar serviços existentes (Sem Build) ---"
	chmod -R 755 config/
	TYPE=$(TYPE) DOCKER_SUFFIX=$(DOCKER_SUFFIX) docker compose up -d --build
	@echo "A aguardar estabilização (5s)..."
	@sleep 5
	@$(MAKE) --no-print-directory docker-status

docker-down:
	@echo "--- [DOCKER-V2] Removendo infraestrutura e contentores ---"
	docker compose down

docker-status:
	@echo "--- [DOCKER-V2] Verificando estado da Nuvem Local ---"
	@TYPE=$(TYPE) DOCKER_SUFFIX=$(DOCKER_SUFFIX) docker compose ps

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
	@echo "--- [DOCKER-RUN] Iniciando ciclo de integridade para TYPE=$(TYPE) ---"
	
	@# 1. Preparação
	chmod -R 755 config/ 2>/dev/null || true
	@mkdir -p reports/docker
	@chmod -R 777 reports/docker 2>/dev/null || true

	@# 2. Build e Up (O Safety já corre aqui dentro do Dockerfile)
	@echo "--- [BUILD] Executando Auditoria e Build (Safety integrado) ---"
	$(MAKE) docker-up TYPE=$(TYPE)
	
	@echo "--- [SYNC] Sincronizando Stack (45s) ---"
	@sleep 45

	@# 3. Extração do Relatório Safety
	@echo "--- [QUALITY] 1. Extraindo Relatórios de Segurança ---"
	@docker cp $$(docker compose ps -q users-service):/reports/docker/safety-report.txt reports/docker/safety-report-users.txt 2>/dev/null || echo "Aviso: Safety Users não encontrado."
	@docker cp $$(docker compose ps -q products-service):/reports/docker/safety-report.txt reports/docker/safety-report-products.txt 2>/dev/null || echo "Aviso: Safety Products não encontrado."

	@# Verificação de segurança: aborta se o Safety encontrou algo
	@if grep -q "VULNERABILITIES FOUND" reports/docker/safety-report-*.txt 2>/dev/null; then \
		echo "❌ Erro: Foram encontradas vulnerabilidades críticas. Pipeline abortado."; \
		exit 1; \
	fi

	@echo "--- [QUALITY] 2. Análise Estática de Código (Black & Bandit) ---"
	@# Black (Linting)
	docker compose exec -T -e PYTHONPATH=$(PKG_PATH) users-service python3 -m black app/ tests/ || exit 1
	docker compose exec -T -e PYTHONPATH=$(PKG_PATH) products-service python3 -m black app/ || exit 1
	
	@# Bandit (Vulnerabilidades no código)
	@echo "Running Bandit on Users and Products..."
	docker compose exec -T -e PYTHONPATH=$(PKG_PATH) users-service python3 -m bandit -r app/ -ll > reports/docker/bandit_users_report.txt 2>&1 || exit 1
	docker compose exec -T -e PYTHONPATH=$(PKG_PATH) products-service python3 -m bandit -r app/ -ll > reports/docker/bandit_products_report.txt 2>&1 || exit 1

	@echo "--- [TESTS] 3. Bateria de Testes Funcionais (Pytest) ---"
	docker compose exec -T \
		-e PYTHONPATH=$(PKG_PATH) \
		-e PRODUCTS_SERVICE_URL=http://products-service:5001 \
		-e USERS_SERVICE_URL=http://users-service:5000 \
		users-service python3 -m pytest -v tests/ | tee reports/docker/tests_report.txt; \
		if [ $${PIPESTATUS[0]} -ne 0 ]; then echo "❌ Testes falharam!"; exit 1; fi

	@echo "--- [STATUS] Ciclo $(TYPE) concluído com sucesso ---"
	$(MAKE) docker-status TYPE=$(TYPE)
	@echo "Relatórios disponíveis em reports/docker/"


docker-trivy-run:
	# 1. Criar a pasta baseada no ambiente 
	$(eval REPORTS_DIR := reports/docker)
	@mkdir -p $(REPORTS_DIR)
	@echo "--- [AUDITORIA] Ambiente: $(ENV) | Imagem: $(TYPE) ---"
	@FAILED=0; \
	for service in users-service products-service; do \
		echo "--- [SCANNING] Analisando $$service:$(TYPE) ---"; \
		docker rm -f temp_$$service 2>/dev/null; \
		docker create --name temp_$$service $$service:$(TYPE); \
		mkdir -p $(REPORTS_DIR)/rootfs_$$service; \
		sudo docker export temp_$$service | tar -C $(REPORTS_DIR)/rootfs_$$service -xf - 2>/dev/null || true; \
		\
		if [ "$(TYPE)" = "pipeline" ]; then \
			trivy fs --severity HIGH,CRITICAL --exit-code 1 --format table \
				--output $(REPORTS_DIR)/trivy_$$service.txt $(REPORTS_DIR)/rootfs_$$service; \
			STATUS=$$?; \
		else \
			trivy fs --severity HIGH,CRITICAL --format table \
				--output $(REPORTS_DIR)/trivy_$$service.txt $(REPORTS_DIR)/rootfs_$$service; \
			STATUS=$$?; \
		fi; \
		\
		if [ $$STATUS -ne 0 ]; then FAILED=1; fi; \
		sudo rm -rf $(REPORTS_DIR)/rootfs_$$service; \
		docker rm -f temp_$$service 2>/dev/null; \
	done; \
	if [ $$FAILED -ne 0 ]; then \
		echo "⚠️ Auditoria concluída com falhas. Interrompendo pipeline."; \
		exit 1; \
	fi
	@echo "✅ Auditoria Trivy concluída com sucesso."

docker-dashboard:
# Para teste local tem de apresentar as credenciais antes de correr o comando:
# export GRAFANA_USER=***** e export GRAFANA_PASS=*****

	@echo "\n===================================================================="
	@echo "    PROVA DE FUNCIONALIDADE: DIAGNÓSTICO DE SAÚDE (V2)"
	@echo "===================================================================="
	
	@echo "[STEP 0] Aguardando Orquestração Nativa (Docker Health)..."
	@# Aguarda até que os serviços marcados como healthy no compose estejam prontos
	@until [ "$$(docker ps --filter "health=healthy" --format "{{.Names}}" | wc -l)" -ge 2 ]; do \
		echo "Aguardando microserviços ficarem 'Healthy'..."; sleep 5; \
	done
	@echo "✅ Microserviços operacionais!"

	@echo "\n[STEP 1] LOKI (porta 3100):"
	@until curl -s http://localhost:3100/ready | grep -q "ready"; do \
		echo "Loki ainda está a carregar..."; sleep 2; \
	done
	@echo "✅ Loki está pronto!"

	@echo "\n[STEP 2] TEMPO (porta 3200):"
	@until curl -s http://localhost:3200/ready | grep -q "ready"; do \
		echo "Tempo ainda está a carregar..."; sleep 2; \
	done
	@echo "✅ Tempo está pronto!"

	@echo "\n[STEP 3] Injetando carga real (Traces e Logs)..."
	@for i in $$(seq 1 25); do \
		curl -s --connect-timeout 2 http://localhost:5000/users > /dev/null; \
		curl -s --connect-timeout 2 http://localhost:5001/e2e/products-with-users > /dev/null; \
		echo -n "."; \
		sleep 0.1; \
	done
	@echo "\n✅ Geração de tráfego concluída."

	@echo "\n[STEP 4] VALIDANDO ACESSO AO GRAFANA:"
	@if [ -z "$(GRAFANA_USER)" ] || [ -z "$(GRAFANA_PASS)" ]; then \
		echo "❌ [FAIL] Credenciais não encontradas!"; exit 1; \
	else \
		if curl -s -f -u $(GRAFANA_USER):$(GRAFANA_PASS) http://localhost:3000/api/health > /dev/null; then \
			echo "✅ [OK] Grafana Autenticado com sucesso"; \
		else \
			echo "❌ [FAIL] Erro de Login no Grafana!"; exit 1; \
		fi; \
	fi

	@echo "\n[STEP 5] OTEL COLLECTOR (porta 4317/4318):"
	@# Verifica se o porto OTLP está à escuta
	@if nc -z localhost 4318; then \
        echo "  -> [OK] OTel Collector está a receber sinais."; \
    else \
        echo "  -> [FAIL] OTel Collector está offline ou bloqueado."; \
		exit 1; \
    fi

	@echo "\n[STEP 6] VALIDANDO ACESSO AO GRAFANA (Segurança):"
	@if [ -z "$(GRAFANA_USER)" ] || [ -z "$(GRAFANA_PASS)" ]; then \
		echo "  -> [FAIL] ERRO CRÌTICO: Credenciais não injetadas no ambiente"; \
		exit 1; \
	else \
		if curl -s -f -u $(GRAFANA_USER):$(GRAFANA_PASS) http://localhost:3000/api/health > /dev/null; then \
			echo "  -> [OK] Autenticação Grafana: SUCESSO (Acesso protegido)"; \
		else \
			echo "  -> [FAIL] Falha de autenticação. Verifique os Secrets do GitHub."; \
			exit 1; \
		fi; \
	fi

	@echo "\n[INFO] ACESSO PARA DEMONSTRAÇÃO:"
	@echo "    Dashboard: $(DASHBOARD_URL)"

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
	
	@echo "--- [TAGGING] Preparando artefactos para a versão $(TYPE) ---"
	# Aqui criamos as tags específicas para cada serviço antes do push
	docker tag $(IMAGE_USERS_TAG) $(URL_USERS)
	docker tag $(IMAGE_PRODUCTS_TAG) $(URL_PRODUCTS)
	
	@echo "--- [PUSH] Enviando imagens para o Registry ---"
	@echo "🚀 Enviando: $(URL_USERS)"
	docker push $(URL_USERS)
	
	@echo "🚀 Enviando: $(URL_PRODUCTS)"
	docker push $(URL_PRODUCTS)
	
	@docker logout
	@echo "--- [OK] Entrega da versão $(TYPE) concluída! ---"
