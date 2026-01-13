# Projecto_Final
*Este projeto foi desenvolvido como parte integrante da avaliação da disciplina de DevOps.*

---

## 🏗️ Microservices CI/CD Pipeline & Observability Stack

Este repositório contém uma solução de engenharia DevOps para microserviços Python, focada em automação, segurança integrada e observabilidade total. O projeto implementa um pipeline de entrega contínua que garante a imutabilidade dos artefactos através de versionamento no Docker Hub.

---

## 📐 1. Arquitetura do Sistema (HLD)

A arquitetura baseia-se em microserviços independentes com instrumentação nativa (OpenTelemetry), orquestrados via Docker e monitorizados por uma stack centralizada que correlaciona logs, métricas e traces.


<p align="center">
  <img src="20260112-HLD-ProjetoFinal-DevOps.drawio.png" alt="Arquitetura do Projeto">
</p>

---

## 📂 2. Estrutura do Projeto

### 📂 Estrutura do Projeto

```text
.
├── app/
│   ├── users/                 # Microserviço de Utilizadores (FastAPI)
│   │   ├── users.py           # Lógica do serviço
│   │   └── Dockerfile.users   # Build da imagem de utilizadores
│   ├── products/              # Microserviço de Produtos (FastAPI)
│   │   ├── products.py        # Lógica do serviço
│   │   └── Dockerfile.products # Build da imagem de produtos
│   └── shared/                # Lógica partilhada entre serviços
│       ├── config.py          # Variáveis de ambiente
│       ├── tracing.py         # Configuração do OpenTelemetry (SDK)
│       └── wait-for-it.sh     # Script para orquestração de arranque
├── config/                    # Configuração da Stack LGTM & Observabilidade
│   ├── grafana/               # Provisionamento de Dashboards e Fontes de Dados
│   ├── loki-config.yml        # Configuração de Agregação de Logs
│   ├── prometheus.yml         # Configuração de Métricas
│   ├── otel-collector-config.yml # Orquestração de Telemetria (Otel)
│   ├── promtail-config.yml    # Agente de recolha de logs (Push para Loki)
│   └── tempo-config.yml       # Configuração de Distributed Tracing
├── tests/                     # Testes Unitários e de Integração (Pytest)
├── docker-compose.yml         # Orquestração de contentores (Deployment Agnóstico)
├── Makefile                   # Automatização de comandos (Build, Up, Down, Test)
├── README.md                  # Documentação técnica e HLD
```

## 🛠️ 3. Ferramentas do Pipeline DevOps

O pipeline integra ferramentas de análise e observabilidade para garantir a qualidade e a visibilidade do software desde a sua construção.

| Categoria | Ferramenta | Função no Projeto |
| :--- | :--- | :--- |
| **Qualidade & Linting** | **Flake8 / Black** | Garantia de estilo (PEP8) e formatação automática. |
| **Testes Unitários** | **Pytest** | Execução de testes automatizados para validação da lógica. |
| **Telemetria** | **OpenTelemetry** | Extração de Traces e Métricas nativas do código. |
| **Observabilidade** | **Stack LGTM** | Visualização correlacionada (Loki, Grafana, Tempo, Prometheus). |
| **Segurança** | **Trivy / Bandit** | Scans de vulnerabilidades em imagens e código (Shift-Left). |
| **Orquestração** | **GitHub Actions** | Automação do CI/CD e gestão de entrega no Docker Hub. |

---

## ✅ 4. Qualidade de Código e Testes

A estabilidade dos microserviços é garantida através de análise estática e testes dinâmicos:

* **Linting:** O **Flake8** e o **Black** asseguram que o código segue as melhores práticas e mantém uma estrutura uniforme.
* **Testes:** O **Pytest** valida as funcionalidades em cada estágio do pipeline.
* **Automação:** Todos os gates de qualidade podem ser validados localmente via `make tests` e `make lint`.

---

## 🔐 5. Segurança e Configuração (.env)

Por razões de segurança, as credenciais de acesso, segredos e tokens de infraestrutura não estão incluídos neste repositório público, evitando a exposição de dados sensíveis.

### Acesso ao Ambiente Local:
A execução completa da infraestrutura (incluindo a autenticação na stack de observabilidade) requer a presença de um ficheiro `.env` na raiz do projeto, utilizado pelo **Makefile** para a injeção de segurança.

Caso o utilizador não seja já detentor do ficheiro `.env`, deverá solicitá-lo ao responsável pelo repositório para proceder à validação local do projeto e acesso aos dashboards.

---

## 🚀 6. Operação e Dashboards

Após a subida da infraestrutura com o comando `make docker-up`:

* **Dashboard de Projeto (Direto):** [http://localhost:3000/d/projeto_final_obs](http://localhost:3000/d/projeto_final_obs)
* **Prometheus UI:** [http://localhost:9090](http://localhost:9090)
* **Acesso:** Utilize as credenciais disponibilizadas no ficheiro `.env`.

---

## 🛡️ 7. Sustentabilidade e Segurança Contínua

Para garantir a longevidade e a resiliência do projeto, foram implementadas as seguintes estratégias de gestão de ciclo de vida:

* **GitHub Dependabot:** O repositório utiliza monitorização ativa para identificar vulnerabilidades em dependências Python (PIP) e atualizações críticas nas GitHub Actions, garantindo que o pipeline não se torne obsoleto.
* **Versionamento Imutável:** O pipeline CI/CD gera tags únicas no Docker Hub baseadas no `GITHUB_RUN_NUMBER`. Esta prática assegura a rastreabilidade total e permite *rollbacks* imediatos para versões anteriores estáveis.
* **Shift-Left Security:** Integração de análise estática de código (Bandit) e scan de imagens (Trivy) diretamente no fluxo de desenvolvimento, impedindo que vulnerabilidades cheguem a produção.

---

## 🧹 8. Manutenção e Limpeza

O projeto inclui mecanismos automatizados via **Makefile** para garantir a higiene do ambiente de desenvolvimento e produção:

* **`make docker-down`**: Interrompe a execução dos microserviços e da stack de observabilidade, removendo a rede virtual e libertando recursos do sistema.
* **`make clean`**: Executa uma limpeza profunda, eliminando caches de Python, ficheiros temporários de testes, volumes de dados locais e relatórios de auditoria antigos.

