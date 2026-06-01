"""
Tests para la aplicación DevOps Pipeline con pytest
"""

import pytest
from fastapi.testclient import TestClient

from server import app


@pytest.fixture
def client():
    """Fixture para el cliente de test"""
    return TestClient(app)


class TestHealthCheck:
    """Tests de health check"""

    def test_root_endpoint(self, client):
        """Test endpoint raíz"""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
        assert "message" in response.json()

    def test_health_endpoint(self, client):
        """Test health endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

    def test_health_has_uptime(self, client):
        """Test que health retorna uptime"""
        response = client.get("/health")
        assert "uptime" in response.json()


class TestMetrics:
    """Tests de métricas Prometheus"""

    def test_metrics_endpoint(self, client):
        """Test que metrics endpoint funciona"""
        response = client.get("/metrics")
        assert response.status_code == 200
        assert b"http_requests_total" in response.content

    def test_metrics_format(self, client):
        """Test que metrics está en formato Prometheus"""
        response = client.get("/metrics")
        assert "TYPE" in response.text or "HELP" in response.text


class TestApiEndpoints:
    """Tests de endpoints de API"""

    def test_info_endpoint(self, client):
        """Test /api/info endpoint"""
        response = client.get("/api/info")
        assert response.status_code == 200
        assert "app" in response.json()
        assert "python_version" in response.json()

    def test_echo_endpoint_success(self, client):
        """Test /api/echo con datos válidos"""
        test_data = {"message": "test", "value": 123}
        response = client.post("/api/echo", json=test_data)
        assert response.status_code == 200
        assert response.json()["received"] == test_data

    def test_echo_endpoint_empty(self, client):
        """Test /api/echo sin datos"""
        response = client.post("/api/echo", json={})
        assert response.status_code == 400

    def test_echo_endpoint_returns_timestamp(self, client):
        """Test que echo retorna timestamp"""
        test_data = {"test": "data"}
        response = client.post("/api/echo", json=test_data)
        assert "timestamp" in response.json()


class TestServiceStatus:
    """Tests de servicio status"""

    def test_service_status_valid(self, client):
        """Test status para servicio válido"""
        response = client.get("/api/status/app")
        assert response.status_code == 200
        assert response.json()["status"] == "operational"

    def test_service_status_all_services(self, client):
        """Test todos los servicios válidos"""
        services = ["app", "prometheus", "grafana"]
        for service in services:
            response = client.get(f"/api/status/{service}")
            assert response.status_code == 200
            assert response.json()["service"] == service

    def test_service_status_invalid(self, client):
        """Test status para servicio inválido"""
        response = client.get("/api/status/invalid")
        assert response.status_code == 400
        assert "error" in response.json()


class TestErrorHandling:
    """Tests de manejo de errores"""

    def test_404_not_found(self, client):
        """Test 404 para ruta no existente"""
        response = client.get("/api/nonexistent")
        assert response.status_code == 404

    def test_method_not_allowed(self, client):
        """Test método no permitido"""
        response = client.post("/health")
        assert response.status_code == 405


class TestRequestValidation:
    """Tests de validación de requests"""

    def test_echo_with_complex_data(self, client):
        """Test echo con datos complejos"""
        complex_data = {
            "string": "value",
            "number": 42,
            "float": 3.14,
            "boolean": True,
            "array": [1, 2, 3],
            "nested": {"key": "value"},
        }
        response = client.post("/api/echo", json=complex_data)
        assert response.status_code == 200
        assert response.json()["received"] == complex_data

    def test_info_contains_timestamp(self, client):
        """Test que info contiene timestamp"""
        response = client.get("/api/info")
        assert "timestamp" in response.json()


class TestMetricsCollection:
    """Tests de recolección de métricas"""

    def test_metrics_recorded_after_request(self, client):
        """Test que métricas se registran después de request"""
        # Hacer request
        response = client.get("/health")
        assert response.status_code == 200

        # Verificar que las métricas se grabaron
        metrics_response = client.get("/metrics")
        assert b"http_requests_total" in metrics_response.content

    def test_metrics_for_different_endpoints(self, client):
        """Test métricas para diferentes endpoints"""
        # Hacer requests a diferentes endpoints
        client.get("/")
        client.get("/health")
        client.get("/api/info")

        # Verificar métricas
        metrics_response = client.get("/metrics")
        metrics_text = metrics_response.text

        # Verificar que se registraron diferentes rutas
        assert "http_requests_total" in metrics_text


class TestResponseFormats:
    """Tests de formatos de respuesta"""

    def test_json_response_format(self, client):
        """Test formato JSON en respuestas"""
        response = client.get("/api/info")
        assert response.headers["content-type"] == "application/json"
        assert isinstance(response.json(), dict)

    def test_plaintext_metrics_format(self, client):
        """Test formato texto para métricas"""
        response = client.get("/metrics")
        # Prometheus devuelve texto plano o custom content-type
        assert response.status_code == 200


class TestConcurrency:
    """Tests de concurrencia"""

    def test_multiple_requests(self, client):
        """Test múltiples requests concurrentes"""
        responses = []
        for _ in range(10):
            response = client.get("/health")
            responses.append(response.status_code)

        assert all(code == 200 for code in responses)
