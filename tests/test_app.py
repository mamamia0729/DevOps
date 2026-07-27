import pytest

from app import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config.update(TESTING=True)
    with app.test_client() as test_client:
        yield test_client


def test_index_reports_service_metadata(client):
    response = client.get("/")

    assert response.status_code == 200
    assert response.get_json()["service"] == "devops-app"


def test_liveness_probe_returns_ok(client):
    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_readiness_probe_returns_ready(client):
    response = client.get("/readyz")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ready"}


def test_unknown_route_returns_404(client):
    assert client.get("/does-not-exist").status_code == 404
