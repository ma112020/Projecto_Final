import logging
import os
from typing import List, Dict, Any

from fastapi import FastAPI, Request
from prometheus_fastapi_instrumentator import Instrumentator

# Importar configurações de Observabilidade
from app.shared.config import setup_logging
from app.shared.tracing import setup_tracing

# Configuração de Logging
setup_logging()
logger = logging.getLogger("users-service")
logger.info("A iniciar users-service...")


# --- Mock Database ---
MOCK_USERS = [
    {"id": 1, "name": "Alice Smith", "email": "alice@example.com", "role": "admin"},
    {"id": 2, "name": "Bob Johnson", "email": "bob@example.com", "role": "user"},
    {"id": 3, "name": "Charlie Brown", "email": "charlie@example.com", "role": "user"},
]

# --- Inicialização do FastAPI ---
app = FastAPI(
    title="Users Service",
    description="Serviço responsável por gerir informações de utilizadores.",
    version="1.0.0",
)

# --- Configuração de Observabilidade ---
setup_tracing(app, os.getenv("OTEL_SERVICE_NAME", "users-service-local"))
Instrumentator().instrument(app).expose(app)


# --- Endpoints ---


@app.get("/health", response_model=Dict[str, str], tags=["Service"])
async def health_check():
    logger.info("Health check executado com sucesso.")
    return {"status": "ok", "service": "users"}


@app.get("/users", response_model=List[Dict[str, Any]], tags=["Users"])
async def get_all_users():
    logger.info("A obter todos os utilizadores.")
    return MOCK_USERS


@app.get("/users/{user_id}", response_model=Dict[str, Any], tags=["Users"])
async def get_user_by_id(request: Request, user_id: int):
    logger.info(f"A procurar utilizador com ID: {user_id}")
    try:
        user = next(u for u in MOCK_USERS if u["id"] == user_id)
        return user
    except StopIteration:
        logger.warning(f"Utilizador com ID {user_id} não encontrado.")
        return {"id": user_id, "name": "Unknown User", "email": "", "role": "guest"}


# --- MOTOR DE ARRANQUE (ADICIONADO) ---
if __name__ == "__main__":
    import uvicorn

    # Adicionado # nosec para silenciar o alerta B104 do Bandit (intencional para Docker)
    # Porta 5000 conforme definido no Makefile
    uvicorn.run(app, host="0.0.0.0", port=5000)  # nosec B104
