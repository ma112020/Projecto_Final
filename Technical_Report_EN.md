# 📄 Technical Report
> **Detailed documentation supporting the technical assessment and DevOps learning journey.**

---

## 🚀 1. Introduction & Learning Milestones

The primary goal of this project was to architect an infrastructure that transcends basic containerization. It represents the implementation of a complete DevOps lifecycle, with a deep focus on automation, proactive security, and end-to-end system visibility.

### 🎯 Strategic Pillars:
* **⚙️ Automated CI/CD:** A robust pipeline for continuous integration and delivery.
* **🛡️ Shift-Left Security:** Integrating vulnerability assessments early in the development cycle.
* **🐳 Optimized Containerization:** Utilizing Docker for slim, high-performance builds.
* **📊 Unified Observability:** Deployment of the LGTM (Loki, Grafana, Tempo, Prometheus) stack.

---

## 📐 2. System Architecture (HLD)

### 2.1. Architectural Workflow
The following diagram showcases the workflow, tracking the code from the initial GitHub commit to the Docker Hub registry, culminating in real-time monitoring via the LGTM stack.

![Project Architecture](20260112-HLD-ProjetoFinal-DevOps.drawio.png)

### 2.2. Microservices Overview
| Service | Technology | Role |
| :--- | :--- | :--- |
| **Users Service** | FastAPI / Python | Managing user profiles, auth, and permissions. |
| **Products Service** | FastAPI / Python | Handling the product catalog and inventory logic. |
| **Shared Logic** | Python Library | A unified layer for data consistency and tracing. |

### 2.3. Project Structure
```text
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
├── .github/workflows/main.yml
├── .gitignore
├── Makefile
├── pytest.ini
├── README.md
├── requirements-dev.txt
├── requirements.txt
└── tests/
    ├── test_products.py
    └── test_users.py
```
---
## 🛠️ 3. CI/CD Pipeline & Code Quality
The GitHub Actions pipeline was engineered to ensure that only verified, high-quality code reaches the production environment:

* **🔍 Static Analysis:** Using **Flake8** and **Black** to enforce consistent coding standards.
* **🧪 Automated Testing:** Mandatory functional validation using **Pytest** across all branches.
* **🛡️ Security Scanning:** Implementation of **Bandit** (SAST) and **Safety** for dependency auditing.
* **📦 Image Governance:** Leveraging **Trivy** to scan for CVEs prior to the final push.
* **🤖 Dependency Tracking:** **Dependabot** provides continuous monitoring for library and base image updates.

---

## 🔐 4. Security & Secrets Management (.env)
In line with industry best practices, sensitive credentials are never hardcoded:

* **Implementation:** Secure management via local **.env** files and **GitHub Secrets** for CI/CD.
* **Governance (The Quality Gate):** Operating under a **"Zero-Exemption"** policy, the removal of the **.trivyignore** file served as the primary control mechanism. This forced technical remediation at the source (image hardening and library patching), ensuring the pipeline acts as an immutable security barrier.
* **Secure Handover:** Local configuration templates are provided separately (via **.zip** file) to maintain the integrity of the public repository.

---

## 📊 5. Observability & Telemetry (LGTM)
The observability framework provides a granular view of the system’s health and performance:

* **🔗 Data Correlation:** Seamless integration of logs, metrics, and traces via **OpenTelemetry**.
* **🔄 LGTM Stack:** Centralized visibility through **Grafana**, **Loki** (Logs), **Tempo** (Tracing), and **Prometheus** (Metrics).
* **⚙️ Automated Provisioning:** Pre-configured dashboards and data sources for "out-of-the-box" monitoring.

---

## ⚠️ 6. Technical Challenges & Lessons Learned
Performing this work and implementing what I learned during the DevOps course was highly rewarding. It was through the practical test that I was able to understand how everything functions and interacts, as well as the system's advantages and vulnerabilities. It became clear how difficult it is to manage the trade-off between security, efficiency, and automation, requiring a constant balance in decision-making:

* **💻 Synchronization and Workflow:** The first lesson was mastering the coordination between local development, branch management (develop), and delivery to the remote repository (main). This rigor in applying the Git methodology allowed the code, README, and this Report to remain in total harmony throughout the project.

* **🛡️ Environment Configuration and Access Security:** The first major challenge was preparing GitHub Actions to respect CI/CD best practices. I investigated how to manage isolation between Development, Staging, and Production environments. I applied the principle that all sensitive data and access credentials for the entire stack (GitHub, Grafana, Docker Hub) must be protected. To resolve permission conflicts between my machine and the GitHub server, I implemented the use of a universal identity (**ID 0:0**), ensuring that infrastructure services could read configurations securely and consistently.

* **🚨 Pipeline Robustness and the Makefile:** During the testing phase, I identified that the pipeline sometimes ignored critical failures. I applied what I learned about error propagation (**exit codes**) in the **Makefile** to ensure that any failure stops the process immediately. I also decided that the Workflow configuration file (** .yml**) itself should use Makefile commands, which made pipeline maintenance much more practical and efficient by centralizing logic in a single location.

* **🌐 Connectivity and Dynamic Orchestration:** I found that communication between services and monitoring failed due to synchronization issues. I investigated alternatives to using static waits and applied dynamic **health checks**. This solution ensured that the stack only proceeded when the network and support services were fully operational.

* **🐳 Docker Multi-stage and Active Security:** To optimize the infrastructure, I applied the **Multi-stage builds** technique, separating the build environment from the execution environment to obtain lighter and more secure images. In the field of security, I used **Trivy** and **Dependabot** for auditing. The central goal and the greatest learning challenge was to achieve a **Zero-CVE** state without compromising project functionality. I used Trivy as a real **Security Gate**.

> **Note:** Although the use of a **.trivyignore** file is a common practice when no patches exist, it was decided that its use would not be acceptable in this project. Thus, the strategy was to raise the level of requirement: instead of "consciously ignoring" existing vulnerabilities, I opted to resolve them at the source, ensuring that nothing passes to production without being 100% verified. (The resolution process can be followed in the **Scenarios** folder.)

#### Security Best Practices Investigation (Hardening Debian -> Alpine):
The **python:slim** (Debian) image presented the vulnerability **CVE-2026-0861** in the **glibc** library. This deep flaw in the OS had no available fix. The decision to migrate to **Alpine Linux** was based on two factors:
* **Attack Surface Reduction:** A minimalist environment with fewer vulnerable components.
* **Base Library Architecture:** Alpine uses **musl**, which is structurally different and immune to the specific **glibc** flaw.
*As a contingency plan, an evaluation of **Wolfi Distroless** images was planned in case Alpine did not guarantee the necessary compliance.*

#### CVE-2026-0994 Management (Protobuf):
The move to Alpine eliminated OS-level flaws, but the scanner detected a new vulnerability in the **Protobuf** library (essential for OpenTelemetry). An infinite recursion attack in this library could cause a DoS in telemetry, which would compromise the project's functionality and was unacceptable. After investigation, I verified the release of a fix patch (**v6.33.5**), which I applied via **requirements.txt**, successfully passing the Trivy verification.
*As a contingency plan, had the patch failed, the action would have been to migrate to the **OpenMetrics** protocol, which, being text-based, would eliminate the dependency on Protobuf's complex binary serialization.*

#### Final Solution:
After resolving the Operating System flaws (via Alpine) and application library flaws (via the Protobuf patch), the final image proved to be, to date, free of flagged vulnerabilities. The project achieved total compliance through an **Unconditional Compliance** policy, resolving problems at the source and ensuring native security in a production environment.

#### 🏷️ Automated Versioning:
I implemented an **Automated Versioning** system based on commit messages. This investigation allowed me to automate version increments (e.g., v1.0.0 to v1.1.0) and ensure that each image on Docker Hub has a unique and traceable identity, allowing for the **Continuous Deployment** of validated artifacts and facilitating software lifecycle management.

**Version History:**
* **v0.0.1 (Baseline):** Initial version with observability infrastructure and functional pipeline.
* **v0.0.2 (Security & Docs):** Dependency updates via Dependabot and technical documentation.
* **v0.0.3 (Hardening Final):** Migration to **Alpine Linux** (resolving CVE-2026-0861) and application of a specific patch for **Protobuf v6.33.5** (resolving CVE-2026-0994). Permanent removal of **.trivyignore**, reaching **Zero-CVE** status.

### **Conclusion**
The completion of this final project allowed for the consolidation of the knowledge acquired throughout the course, applying it within a microservices scenario. The decision to integrate vulnerability scanning tools (**Trivy**) from the earliest stages proved to be an additional challenge, requiring an in-depth study of base image security and dependency management.

This process was essential for understanding the importance of rigor in continuous delivery: the impossibility of allowing vulnerabilities in production (such as the identified CVE-2026-0861 and CVE-2026-0994) necessitated the investigation of advanced Hardening solutions, such as the migration to Alpine Linux and strategic library updates.

The final result is an infrastructure that not only meets all functional and observability requirements but also adheres to security-by-design best practices. This work concludes with the certainty that security and automation are inseparable in a resilient DevOps ecosystem.

---

## 🧹 7. Maintenance & Sustainability
The project includes dedicated routines for environment upkeep:
* **make docker-down:** Cleanly stops services and removes virtual networks.
* **make clean:** Performs a deep purge of caches, volumes, and temporary build artifacts.

---

## 🚀 8. Future Roadmap and Proposed Improvements
While the project has successfully achieved its initial milestones, transitioning to a production-ready environment requires moving from "reactive" security to a proactive security model.

#### 🛡️ Governance via SBOM (Software Bill of Materials)
To break the cycle of reactive vulnerability patching, the most critical improvement would be the implementation of an automated SBOM generation and auditing workflow. This approach would enable:
* **Full Visibility (Shift-Left):** Leveraging tools like **Syft** to generate a digital "identity card" for every image, cataloging every library and version before the build process even begins.
* **Instant Auditing:** Integrating **Grype** or **Trivy** to scan the SBOM file and automatically block obsolete or vulnerable dependencies at the source. This would automate the investigation process, which was performed manually during this phase.
* **Upstream Automation:** Implementing **Renovate Bot** to ensure that base images (such as Alpine) and libraries (such as Protobuf) are updated automatically via Pull Requests whenever a newer stable version is released.

#### 💾 Persistence and Service-to-Service Communication
The next technical evolution to make the application fully functional would be the integration of a containerized Database (e.g., PostgreSQL or Redis).
* **Real Data for Procurement:** Adding a persistence layer would allow for the collection of high-fidelity metrics regarding **Disk I/O** and **write latency** via OpenTelemetry.
* **Service Continuity:** The application would move away from a volatile state, allowing for data storage across container restarts—a fundamental requirement for end-users.

#### 📊 Procurement and Cloud Scalability
The initial choice for a cloud-agnostic solution was intentional to ensure portability and zero cost. However, future scalability must be addressed. The next step involves a detailed **Procurement analysis** to identify the cloud provider that best supports the application's growth based on the consumption metrics already gathered.

By utilizing consolidated CPU, RAM, and IOPS metrics, a data-driven cloud migration analysis can be performed:
* **Efficient Sizing:** Preventing over-provisioning by selecting instances precisely tuned to the actual workload (**Right-sizing**).
* **Provider Comparison:** Evaluating the feasibility of maintaining the stack on **Free Tier** instances (e.g., Oracle Cloud) versus migrating to managed services (e.g., AWS RDS, Google Cloud SQL, or Azure) as traffic scales.



