# # 📄 Relatório Técnico 

**Projeto:** Microservices Pipeline & Observability Stack  
**Objetivo:** Documento de suporte à avaliação técnica e percurso de aprendizagem.

---

## 🚀 1. Introdução e Percurso de Aprendizagem

Neste projeto, o foco foi construir uma infraestrutura que fosse além da simples conteinerização. O objetivo foi implementar um ciclo completo de DevOps, priorizando automação, segurança e visibilidade.

### 🎯 Pilares Estratégicos:
* **⚙️ Pipeline CI/CD Automatizado:** Fluxo automático de validação e entrega via GitHub Actions.
* **🛡️ Segurança Shift-Left:** Verificação de vulnerabilidades (CVEs) no código e imagens.
* **🐳 Ambiente Conteinerizado:** Uso de Docker com builds multi-stage e imagens otimizadas.
* **📊 Observabilidade Centralizada:** Implementação da stack LGTM (Loki, Grafana, Tempo, Prometheus).

---

## 📐 2. Arquitetura do Sistema (HLD)

### 2.1. Desenho da Arquitetura Implementada
O diagrama ilustra o fluxo de trabalho, desde o commit no GitHub até à publicação no Docker Hub e monitorização na stack LGTM.

![Arquitetura do Projeto](20260112-HLD-ProjetoFinal-DevOps.drawio.png)

### 2.2. Microserviços e Estrutura
| Serviço | Tecnologia | Função |
| :--- | :--- | :--- |
| **Users Service** | FastAPI / Python | Gestão de utilizadores e permissões. |
| **Products Service** | FastAPI / Python | Gestão de catálogo e inventário. |
| **Shared Logic** | Python Lib | Camada comum para consistência de dados e tracing. |

### 2.3. Estrutura de Diretórios Atualizada
* **app/**: Contém os serviços de Users e Products (FastAPI).
* **config/**: Configurações da stack LGTM (Grafana, Loki, Prometheus, OTEL).
* **.github/workflows/**: Automação do pipeline CI/CD.
* **tests/**: Testes unitários e funcionais.
* **Raiz/**: Ficheiros de orquestração (Docker-compose, Makefile, README, Relatórios).

---

## 🛠️ 3. Pipeline CI/CD e Qualidade de Código

O pipeline foi estruturado para garantir que apenas código validado chega ao repositório de produção:

1. **Linting:** Flake8 e Black para uniformização do código.
2. **Testes:** Pytest para validação funcional obrigatória.
3. **Segurança Estática:** Bandit (análise de código) e Safety (dependências).
4. **Auditoria de Imagem:** Scan do **Trivy** em busca de CVEs antes do push.
5. **Automação:** Dependabot para monitorização ativa de patches de segurança.

---

## 🔐 4. Segurança e Gestão de Segredos

Seguindo as melhores práticas, as credenciais sensíveis nunca são expostas:

* **Implementação:** Uso de GitHub Secrets para o pipeline e ficheiros `.env` locais (não versionados).
* **Governação:** Aplicação de uma política de **Conformidade Incondicional**. Foi eliminada a utilização do ficheiro `.trivyignore`, forçando a resolução técnica de cada vulnerabilidade na origem.
* **Integridade:** O ficheiro de configuração local é enviado separadamente no ficheiro comprimido (.zip) para proteger a integridade do repositório público.

---

## 📊 5. Observabilidade e Telemetria (LGTM)

A stack de observabilidade permite uma correlação direta entre diferentes sinais:

* **Métricas:** Recolhidas pelo Prometheus para monitorizar performance.
* **Logs:** Centralizados no Loki para depuração rápida.
* **Traces:** Gerados pelo Tempo via OpenTelemetry para rastrear pedidos entre serviços.
* **Visualização:** Dashboards unificados no Grafana (conforme evidenciado na imagem `Dashboard_alpine.png`).

---

## ⚠️ 6. Desafios e Aprendizagens Técnicas

### 🛡️ Hardening e a Jornada "Zero-CVE"
O maior desafio técnico foi atingir um estado livre de vulnerabilidades sem comprometer a funcionalidade.

* **Caso Debian (glibc):** A imagem `python:slim` apresentava a **CVE-2026-0861** na `glibc`. A solução foi a migração para **Alpine Linux** (baseada em `musl`), eliminando a superfície de ataque.
* **Caso Protobuf:** Detetada a **CVE-2026-0994**. A resolução passou pela investigação e aplicação do patch específico para a versão **6.33.5** via `requirements.txt`.

### 🚨 Robustez e Automação
* **Makefile:** Implementação de propagação de erros para garantir que o pipeline pare imediatamente em caso de falha.
* **Docker Multi-stage:** Separação entre ambiente de build e runtime, resultando em imagens mais leves e seguras.

**Histórico de Versões:**
* **v0.0.1 (Baseline):** Versão inicial funcional.
* **v0.0.2 (Security):** Introdução de scans de segurança e auditoria.
* **v0.0.3 (Hardening Final):** Migração para Alpine e resolução total de CVEs. Estado final: **Zero-CVE**.

---

## 🚀 7. Sugestões de Melhoria e Trabalho Futuro

#### 🛡️ Governação via SBOM
Implementação de **SBOM** (Software Bill of Materials) utilizando **Syft** e **Grype** para automatizar o inventário de componentes e a auditoria proativa de segurança.

#### 📊 Procurement Cloud
Transição para serviços geridos (AWS EKS ou Azure AKS) com base numa análise de **Right-sizing**, utilizando os dados de consumo de CPU/RAM recolhidos pela stack LGTM para otimizar custos e performance.

#### 📊 Procurement Cloud
Transição para serviços geridos (AWS EKS ou Azure AKS) com base numa análise de **Right-sizing**, utilizando os dados de consumo de CPU/RAM recolhidos.
