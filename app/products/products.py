import logging
import os
import asyncio
from contextlib import asynccontextmanager
from typing import Dict, Any
import httpx
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from app.shared.config import setup_logging
from app.shared.tracing import setup_tracing

setup_logging()
logger = logging.getLogger("products-service")


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient()
    yield
    await app.state.http_client.aclose()


app = FastAPI(title="Products Service", lifespan=lifespan)

USERS_SERVICE_URL = os.getenv("USERS_SERVICE_URL", "http://localhost:5000")

setup_tracing(app, os.getenv("OTEL_SERVICE_NAME", "products-service"))
Instrumentator().instrument(app).expose(app)

MOCK_PRODUCTS = [
    {"id": 101, "name": "Laptop Pro", "price": 1200.0, "owner_id": 1},
    {"id": 102, "name": "Mouse Sem Fios", "price": 25.5, "owner_id": 2},
    {"id": 103, "name": "Monitor 4K", "price": 450.0, "owner_id": 3},
]


async def fetch_user_info(user_id: int) -> Dict[str, Any]:
    url = f"{USERS_SERVICE_URL}/users/{user_id}"
    response = await app.state.http_client.get(url)
    response.raise_for_status()
    return response.json()


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "products"}


@app.get("/products")
async def get_all_products():
    return MOCK_PRODUCTS


@app.get("/e2e/products-with-users")
async def get_products_with_user_info():
    tasks = [fetch_user_info(p["owner_id"]) for p in MOCK_PRODUCTS]
    user_results = await asyncio.gather(*tasks)
    user_map = {u["id"]: u for u in user_results}
    return [
        {"product": p, "owner": user_map.get(p["owner_id"], {"name": "Unknown"})}
        for p in MOCK_PRODUCTS
    ]


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=5001)  # nosec B104
