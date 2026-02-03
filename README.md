# Projecto_Final
*Este projeto foi desenvolvido como parte integrante da avaliação da disciplina de DevOps Engineering.*

---

## 🏗️ Microservices CI/CD Pipeline & Observability Stack


Este repositório contém uma solução de engenharia DevOps para microserviços Python, focada em automação, segurança integrada e observabilidade total. O projeto implementa um pipeline de Continuous Integration (CI), Continuous Delivery (CD) e Continuous Deployment, garantindo a imutabilidade dos artefactos através do versionamento automatizado no Docker Hub.

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
├── 20260112-HLD-ProjetoFinal-DevOps.drawio.png
├── app
│   ├── __init__.py
│   ├── products
│   │   ├── Dockerfile.products
│   │   ├── __init__.py
│   │   ├── products.py
│   │   └── requirements.txt
│   ├── shared
│   │   ├── config.py
│   │   ├── __init__.py
│   │   ├── tracing.py
│   │   └── wait-for-it.sh
│   └── users
│       ├── Dockerfile.users
│       ├── __init__.py
│       ├── requirements.txt
│       └── users.py
├── config
│   ├── grafana
│   │   ├── dashboards
│   │   └── provisioning
│   ├── grafana-datasources.yml
│   ├── loki-config.yml
│   ├── otel-collector-config.yml
│   ├── prometheus.yml
│   ├── promtail-config.yml
│   └── tempo-config.yml
├── config_temp_prom
│   └── prometheus.yml
├── docker-compose.yml
├── Makefile
├── pytest.ini
├── README.md
├── README_original.md
├── requirements-dev.txt
├── requirements.txt
└── tests
    ├── __init__.py
    ├── test_products.py
    └── test_users.py
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

Para garantir a longevidade e a resiliência do projeto, foram implementadas as seguintes estratégias de gestão de ciclo de vida, documentada nas execuções de pipeline:

* **Versionamento Imutável:** O pipeline CI/CD gera tags únicas no Docker Hub baseadas no histórico de builds. Esta prática assegura a rastreabilidade total e permite **Continuous Deployment** de artefactos validados.
* **Histórico de Versões:**
    * **v0.0.1 (Baseline):** Versão inicial com infraestrutura de observabilidade e pipeline funcional.
    * **v0.0.2 (Security & Docs):** Atualização de dependências via Dependabot e documentação técnica.
    * **v0.0.3 (Hardening Final):** Migração para **Alpine Linux** (resolução da CVE-2026-0681) e aplicação de patch específico para **Protobuf v6.33.5** (resolução da CVE-2026-0994). **Remoção definitiva do .trivyignore**, atingindo o estado de **Zero-CVE**.
* **GitHub Dependabot:** Monitorização ativa de dependências (PIP) e segurança das GitHub Actions.
* **Shift-Left Security:** Scans de segurança automatizados (**Trivy**) que garantem a integridade da **Continuous Delivery**, bloqueando a branch `main` em caso de falha de segurança ou vulnerabilidades críticas, eliminando a necessidade de exceções manuais.

---

## 🧹 8. Manutenção e Limpeza

O projeto inclui mecanismos automatizados via **Makefile** para garantir a higiene do ambiente de desenvolvimento e produção:

* **`make docker-down`**: Interrompe a execução dos microserviços e da stack de observabilidade, removendo a rede virtual e libertando recursos do sistema.
* **`make clean`**: Executa uma limpeza profunda, eliminando caches de Python, ficheiros temporários de testes, volumes de dados locais e relatórios de auditoria antigos.

