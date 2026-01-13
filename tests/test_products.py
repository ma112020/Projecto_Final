import pytest
import httpx
import os

# Configuração de URLs conforme o teu ambiente local
PRODUCTS_SERVICE_URL = os.getenv("PRODUCTS_SERVICE_URL", "http://localhost:5001")


@pytest.mark.asyncio
async def test_products_service_health():
    """Verifica se o serviço de produtos está online na porta 5001"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{PRODUCTS_SERVICE_URL}/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_read_products_standalone():
    """Verifica a listagem de produtos no serviço"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{PRODUCTS_SERVICE_URL}/products")
        assert response.status_code == 200
        data = response.json()
        assert len(data) > 0
        assert data[0]["name"] == "Laptop Pro"


@pytest.mark.asyncio
async def test_e2e_service_communication():
    """
    Teste de Integração (E2E):
    Verifica se o serviço de Produtos (5001) consegue comunicar
    com o serviço de Utilizadores (5000) com sucesso.
    """
    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.get(f"{PRODUCTS_SERVICE_URL}/e2e/products-with-users")
        assert response.status_code == 200

        data = response.json()
        # Valida se a integração trouxe dados do dono do produto
        for item in data:
            assert "product" in item
            assert "owner" in item
            # Verifica se o enriquecimento de dados funcionou
            if item["product"]["owner_id"] == 1:
                assert item["owner"]["name"] == "Alice Smith"
