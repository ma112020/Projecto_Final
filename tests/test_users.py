import pytest
import httpx
import os

# Definição da URL do serviço
USERS_SERVICE_URL = os.getenv("USERS_SERVICE_URL", "http://localhost:5000")


@pytest.mark.asyncio
async def test_users_service_health():
    """Testa o endpoint de saúde do serviço de utilizadores."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{USERS_SERVICE_URL}/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_read_users_standalone():
    """Testa a listagem completa de utilizadores."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{USERS_SERVICE_URL}/users")
        assert response.status_code == 200

        data = response.json()
        assert isinstance(data, list)

        # Sincronizado com os dados do serviço: Bob Johnson e não Jones
        names = [user["name"] for user in data]
        assert "Alice Smith" in names
        assert "Bob Johnson" in names
        assert "Charlie Brown" in names


@pytest.mark.asyncio
async def test_get_single_user():
    """Testa a recuperação de um utilizador específico."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{USERS_SERVICE_URL}/users")
        data = response.json()
        user_id_1 = next((u for u in data if u["id"] == 1), None)
        assert user_id_1 is not None
        assert user_id_1["name"] == "Alice Smith"


@pytest.mark.asyncio
async def test_users_invalid_endpoint():
    """Verifica 404 em endpoint inexistente."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{USERS_SERVICE_URL}/non-existent")
        assert response.status_code == 404
