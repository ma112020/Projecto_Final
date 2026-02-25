<style>
  /* CONFIGURAÇÃO GLOBAL DE MARGENS */
  body { 
    font-family: "Segoe UI", Arial, sans-serif; 
    line-height: 1.6; 
    text-align: justify; 
    color: #333; 
    max-width: 750px; /* Reduzido ligeiramente para dar espaço às margens */
    margin-top: 0;
    margin-bottom: 0;
    margin-right: auto;
    margin-left: 12%; /* Margem esquerda reforçada para todo o documento */
    padding-right: 5%; 
  }
  
  .header-container { text-align: center; border-bottom: 3px solid #2c3e50; padding-bottom: 15px; margin-bottom: 30px; margin-top: 20px; }
  h1 { color: #2c3e50; font-size: 2.2em; margin-bottom: 5px; }
  .subtitle { font-style: italic; color: #7f8c8d; font-size: 1.1em; }
  
  h2 { color: #2980b9; border-bottom: 1px solid #eee; padding-bottom: 5px; margin-top: 40px; }
  h3 { color: #16a085; margin-top: 20px; margin-bottom: 10px; }

  /* TABELA DE DIRETÓRIOS - MANTENDO A EXPANSÃO VERTICAL */
  .tree-container {
    width: 100%;
    margin-top: 15px;
    page-break-inside: avoid;
  }

  .tree-table {
    border-collapse: collapse;
    width: 100%; 
    border: 1.5px solid #d1d1d1;
    background-color: #fcfcfc;
    border-radius: 8px;
  }

  .tree-table td {
    font-family: "Consolas", "monaco", monospace;
    font-size: 13px !important; 
    line-height: 1.85 !important; 
    padding: 55px 40px !important; 
    white-space: pre;
    color: #2c3e50;
    vertical-align: top;
  }

  img { display: block; margin: 25px auto; max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; }
  
  /* Ajuste para as tabelas normais do texto */
  table:not(.tree-table) { width: 100%; border-collapse: collapse; margin: 20px 0; }
  table:not(.tree-table) th, table:not(.tree-table) td { border: 1px solid #ddd; padding: 12px; }
</style>

<div class="header-container">
  <h1>📄 Relatório Final</h1>
  <div class="subtitle">Documento detalhado de suporte à avaliação técnica e percurso de aprendizagem.</div>

## 🚀 1. Introdução e Percurso de Aprendizagem

Neste projeto, o foco foi construir uma infraestrutura que fosse além da simples conteinerização. O objetivo foi implementar um ciclo completo de DevOps, priorizando automação, segurança e visibilidade.

<div style="page-break-inside: avoid;">

### 🎯 Pilares Estratégicos:
* ⚙️ **Pipeline CI/CD Automatizado:** Fluxo automático de validação e entrega.
* 🛡️ **Segurança Shift-Left:** Verificação de vulnerabilidades no código e imagens.
* 🐳 **Ambiente Conteinerizado (Docker):** Uso de imagens leves e builds otimizados.
* 📊 **Observabilidade Centralizada:** Implementação da stack LGTM.

</div>

<div style="page-break-after: always;"></div>

---

## 📐 2. Arquitetura do Sistema (HLD)

### 2.1. Desenho da Arquitetura Implementada
O diagrama ilustra o fluxo de trabalho, desde o commit no GitHub até à publicação no Docker Hub e monitorização na stack LGTM.



<p align="center">
  <img src="20260112-HLD-ProjetoFinal-DevOps.drawio.png" alt="Arquitetura do Projeto">
</p>

### 2.2. Microserviços e Estrutura
| Serviço | Tecnologia | Função |
| :--- | :--- | :--- |
| **Users Service** | FastAPI / Python | Gestão de utilizadores e permissões. |
| **Products Service** | FastAPI / Python | Gestão de catálogo e inventário. |
| **Shared Logic** | Python Lib | Camada comum para consistência de dados. |

<div style="page-break-after: always;"></div>

### 2.3. Estrutura de Diretórios

<div class="tree-container">
<table class="tree-table">
<tr>
<td>.
.
├── 20260112-HLD-ProjetoFinal-DevOps.drawio.png
├── app
│   ├── products/
│   │   ├── Dockerfile.products
│   │   └── products.py
│   ├── shared/
│   │   ├── config.py
│   │   └── tracing.py
│   └── users/
│       ├── Dockerfile.users
│       └── users.py
├── config/
│   ├── grafana/
│   ├── loki-config.yml
│   ├── otel-collector-config.yml
│   ├── prometheus.yml
│   └── tempo-config.yml
├── docker-compose.yml
├── .env
├── .github
│   └── workflows
│       └── main.yml
├── .gitignore
├── Makefile
├── pytest.ini
├── README.md
├── requirements-dev.txt
├── requirements.txt
├── Scenarios/                      # Laboratório de investigação de CVEs
│   ├── 00_baseline_slim_image/     # Teste inicial (Debian)
│   └── 01_alpine_image_attempt/    # Validação de Hardening
└── tests/
    ├── test_products.py
    └── test_users.py
</tr>
</table>
</div>

## 🛠️ 3. Pipeline CI/CD e Qualidade de Código

O pipeline no GitHub Actions foi estruturado para garantir que apenas código validado chega ao repositório de produção:

* 🔍 **Qualidade (Linting):** Utilização do Flake8 e Black para uniformização do código.
* 🧪 **Testes (Pytest):** Validação funcional obrigatória em todos os estágios.
* 🛡️ **Segurança:** Implementação do Bandit e Safety.
* 📦 **Auditoria de Imagem:** Scan do Trivy em busca de CVEs antes do push final.
* 🤖 **Dependabot:** Monitorização ativa de segurança para bibliotecas e imagens base.

</div>

<hr>

<div class="no-break">

## 🔐 4. Segurança e Gestão de Segredos (.env)

Seguindo as melhores práticas, as credenciais sensíveis nunca são expostas:

* **Implementação:** Uso de ficheiros .env protegidos e GitHub Secrets para o pipeline.
* **Governação:** Seguindo o princípio de conformidade incondicional, utilizando a eliminação do ficheiro .trivyignore como o principal mecanismo de controlo (Quality Gate). Em vez de permitir exceções para vulnerabilidades conhecidas, a política aplicada forçou a resolução técnica diretamente na origem através do hardening de imagens e atualização de bibliotecas, garantindo um sistema de governação transparente, onde a pipeline de CI/CD atua como uma barreira imutável que impede o avanço de qualquer componente inseguro e obriga a uma intervenção de engenharia real em vez de um simples bypass administrativo."
* **Entrega:** O ficheiro de configuração local é enviado separadamente no ficheiro comprimido (.zip) para proteger a integridade do repositório público.

</div>

<hr>

<div class="no-break">

## 📊 5. Observabilidade e Telemetria (LGTM)

A stack de observabilidade permite uma visão detalhada do comportamento do sistema:

* 🔗 **Integração:** Correlação entre logs, métricas e traces via OpenTelemetry.
* 🔄 **Stack LGTM:** Centralização no Grafana, Loki, Tempo e Prometheus.
* ⚙️ **Automação:** Provisionamento automático de dashboards e datasources.

---

## ⚠️ 6. Desafios e Aprendizagens Técnicas

Foi muito aliciante realizar este trabalho e poder implementar o que aprendi durante o curso de DevOps. Foi através do teste prático que consegui perceber como tudo funciona e interage, as vantagens e as vulnerabilidades do sistema. Ficou claro como é difícil a gestão de compromisso entre segurança, eficiência e automação, exigindo um equilíbrio constante na tomada de decisões:

💻 **Sincronização e Fluxo de Trabalho:** A primeira aprendizagem foi dominar a articulação entre o desenvolvimento na máquina local, a gestão de branches (develop) e a entrega no repositório remoto (main). Este rigor na aplicação da metodologia Git permitiu manter o código, o README e este Relatório em total sintonia durante todo o projeto.

🛡️ **Configuração de Ambientes e Segurança de Acessos:** O primeiro grande desafio foi preparar o GitHub Actions para respeitar as boas práticas de CI/CD. Investiguei como gerir o isolamento entre os ambientes de Development, Staging e Production.
Apliquei o princípio de que todos os dados sensíveis e credenciais de acesso a toda a stack (GitHub, Grafana, Docker Hub) devem ser protegidos. Para resolver conflitos de permissões entre a minha máquina e o servidor do GitHub, implementei o uso de uma identidade universal (ID 0:0), garantindo que os serviços de infraestrutura conseguissem ler as configurações de forma segura e consistente.


🚨 **Robustez do Pipeline e o Makefile:** Durante a fase de testes, identifiquei que o pipeline por vezes ignorava falhas críticas. Apliquei o que aprendi sobre propagação de erros (exit codes) no Makefile para garantir que qualquer falha interrompa o processo imediatamente. Decidi também que o próprio ficheiro de configuração do Workflow (.yml) deve utilizar os comandos do Makefile, o que tornou a manutenção do pipeline muito mais prática e eficiente, centralizando a lógica num único local.

🌐 **Conetividade e Orquestração Dinâmica:** Verifiquei que a comunicação entre os serviços e a monitorização falhava por problemas de sincronização. Investiguei alternativas ao uso de esperas estáticas e apliquei verificações de saúde dinâmicas (health checks). Esta solução garantiu que a stack só avançasse quando a rede e os serviços de suporte estivessem totalmente operacionais.

🐳 **Docker Multi-stage e Segurança Ativa:** Para otimizar a infraestrutura, apliquei a técnica de Multi-stage builds, separando o ambiente de construção do de execução para obter imagens mais leves e seguras. No campo da segurança, utilizei o Trivy e o Dependabot para auditoria. O objetivo central e o maior desafio de aprendizagem foi o de atingir o estado de **Zero-CVE** sem comprometimento da funcionalidade do projecto. Apliquei a técnica de **Multi-stage builds** para obter imagens leves e utilizei o **Trivy** como um *Security Gate* real.

**Nota:** Embora o uso do ficheiro `.trivyignore` seja uma prática comum quando não existem patches, foi decidido que a sua utilização não seria aceitável neste projecto. Assim a estratégia passou por elevar o nível de exigência: em vez de "ignorar conscientemente" as vulnerabilidades existentes, optei por resolvê-las na origem, garantindo que nada passe para produção sem estar 100% verificado. (O processo de resolução poderá ser acompanhado na pasta Scenarios.)

* **Investigação boas práticas segurança (Hardening Debian -> Alpine):**
    A imagem `python:slim` (Debian) apresentava a vulnerabilidade **CVE-2026-0861** na biblioteca **`glibc`**. Esta falha profunda no SO não tinha correção disponível. A decisão de migrar para **Alpine Linux** baseou-se em dois fatores:
    1.  **Redução da Superfície de Ataque:** Um ambiente minimalista com menos componentes vulneráveis.
    2.  **Arquitetura da Biblioteca Base:** A Alpine utiliza a **`musl`**, que é estruturalmente diferente e imune à falha específica da `glibc`.
    Como plano de contingência, estava prevista a avaliação de imagens **Wolfi Distroless** caso a Alpine não garantisse a conformidade necessária.

* **Gestão da CVE-2026-0994 (Protobuf):**
    A mudança para Alpine eliminou as falhas de SO, mas o scanner detetou uma nova vulnerabilidade na biblioteca **Protobuf** (essencial para o OpenTelemetry). Um ataque de recursão infinita nesta biblioteca poderia causar um DoS na telemetria, o que comprometeria a funcionalidade do projeto e não seria aceitável. Após investigação, verifiquei o lançamento do patch de correção (**v6.33.5**), que apliquei via `requirements.txt`, superando a verificação do Trivy. 
    Como plano de contingência, caso o patch falhasse, a acção passaria pela migração para o protocolo **OpenMetrics**, que por ser baseado em texto, eliminaria a dependência da serialização binária complexa do Protobuf.

* **Solução Final** Após a resolução das falhas de Sistema Operativo (via Alpine) e de bibliotecas aplicacionais (via patch do Protobuf), a imagem final provou estar, até à data, livre de vulnerabilidades assinaladas. O projeto atingiu conformidade total através de uma política de Conformidade Incondicional, resolvendo os problemas na origem e garantindo uma segurança nativa em ambiente de produção.

🏷️ **Versionamento Automático:** Implementei um sistema de Automated Versioning baseado em mensagens de commit. Esta investigação permitiu-me automatizar a subida de versões (ex: v1.0.0 para v1.1.0) e garantir que cada imagem no Docker Hub tenha uma identidade única e rastreável, permintindo o *Continuous Deployment** de artefactos validados, facilitando a gestão do ciclo de vida do software.
**Histórico de Versões:**
*  **Histórico de Versões:**
    * **v0.0.1 (Baseline):** Versão inicial com infraestrutura de observabilidade e pipeline funcional.
    * **v0.0.2 (Security & Docs):** Atualização de dependências via Dependabot e documentação técnica.
    * **v0.0.3 (Hardening Final):** Migração para **Alpine Linux** (resolução da CVE-2026-0681) e aplicação de patch específico para **Protobuf v6.33.5** (resolução da CVE-2026-0994). **Remoção definitiva do .trivyignore**, atingindo o estado de **Zero-CVE**.

**Conclusão** A realização deste projeto final permitiu consolidar os conhecimentos adquiridos ao longo da disciplina, aplicando-os num cenário de microserviços. A decisão de integrar ferramentas de scan de vulnerabilidades (Trivy) desde as fases iniciais revelou-se um desafio acrescido, que exigiu um estudo aprofundado sobre a segurança de imagens base e gestão de dependências.

Este processo foi essencial para compreender a importância do rigor na entrega contínua: a impossibilidade de permitir vulnerabilidades em produção (como as identificadas CVE-2026-0861 e CVE-2026-0994) obrigou à investigação de soluções de Hardening avançadas, como a migração para Alpine Linux e a atualização estratégica de bibliotecas.

O resultado final é uma infraestrutura que não só cumpre todos os requisitos funcionais e de observabilidade, como também adere às melhores práticas de segurança por design. Este trabalho termina com a certeza de que a segurança e a automação são indissociáveis num ecossistema DevOps resiliente."

<div style="page-break-after: always;"></div>


## 🧹 7. Limpeza e Manutenção

O projeto inclui ferramentas de limpeza total para garantir a sustentabilidade do ambiente:

* `make docker-down`: Paragem e remoção de redes.
* `make clean`: Limpeza de caches e volumes.

---

## 🧪 8. Galeria de Evidências Técnicas (Snapshots de Prova)
Em pasta anexa, poderão ser encontrados as evidências técnicas dos testes locais (em formato .png) da montagem do repositório no Github e teste do pipeline ci/cd no Github Actions, o resultado de todos os testes realizados, bem como evidência da paragem, desmontagem e limpeza da infraestrutura criada.

---

## 🚀 9. Sugestões de Melhoria e Trabalho Futuro

Embora o projeto tenha atingido os seus objetivos iniciais, a evolução para um ambiente de produção real exige a transição de uma segurança "reativa" para uma **segurança proativa**.

#### 🛡️ Implementação de Governação via SBOM (Software Bill of Materials)
Para evitar o ciclo de correções reativas de vulnerabilidades, a melhoria fundamental seria a implementação de uma rotina automatizada de geração e auditoria de **SBOM**. Esta abordagem permitiria:

* **Visibilidade Total (Shift-Left):** Utilizar ferramentas como o **Syft** para gerar um "bilhete de identidade" de cada imagem, listando cada biblioteca e versão antes mesmo de iniciar o build.
* **Auditoria Instantânea:** Integrar o **Grype** ou o **Trivy** para ler o ficheiro SBOM e barrar dependências obsoletas ou vulneráveis na origem, automatizando o processo de investigação que nesta fase foi manual.
* **Automação de Upstream:** Implementar o **Renovate Bot** para garantir que as imagens base (como a Alpine) e as bibliotecas (como o Protobuf) sejam atualizadas automaticamente através de Pull Requests sempre que surja uma versão estável mais recente.


<div style="page-break-after: always;"></div>


#### 💾 Persistência e Comunicação Service-to-Service
O próximo passo técnico para tornar a aplicação funcional seria a integração de uma **Base de Dados** (ex: PostgreSQL ou Redis) devidamente contentorizada.
* **Dados Reais para Procurement:** A adição de persistência permitiria recolher métricas precisas de **I/O de disco** e **latência de escrita** via OpenTelemetry.
* **Continuidade de Serviço:** A aplicação deixaria de ser volátil, permitindo o armazenamento de estados entre reinícios de contentores, algo essencial para utilizadores finais.

#### 📊 Procurement e Escalabilidade Cloud
Embora tenha sido intencional a escolha por uma solução inicial agnóstica que garante portabilidade e custo zero, tenho a plena noção de que é necessário acautelar a escalabilidade futura dos serviços. Nesse sentido, o passo seguinte seria realizar uma análise detalhada de custos (Procurement) para identificar qual o fornecedor de Cloud que melhor suportaria o crescimento da aplicação com base nas métricas de consumo já recolhidas.

Com as métricas de consumo de CPU, RAM e IOPS consolidadas, seria possível realizar uma análise de custos fundamentada para a migração para a Cloud:
* **Dimensionamento Eficiente:** Evitar o *over-provisioning* através da escolha de instâncias ajustadas à carga real (Right-sizing).
* **Comparação de Fornecedores:** Avaliar a viabilidade de manter a stack em instâncias **Free Tier** (ex: Oracle Cloud) vs. a migração para serviços geridos (ex: AWS RDS/Google Cloud SQL) à medida que o tráfego escala.
