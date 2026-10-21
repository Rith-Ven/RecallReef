from fastapi.testclient import TestClient

import database
from main import app
from datetime import timezone


def test_polyp_survives_app_restart(tmp_path, monkeypatch):
    # Redirect database operations to a temporary test file.
    test_database = tmp_path / "test_recallreef.db"
    monkeypatch.setattr(database, "DATABASE_PATH", test_database)

    polyp = {
        "id": "91f2d986-48ee-421a-882d-1d411f2d885e",
        "taskTitle": "Persistence test",
        "stoppingPoint": "Created a test record.",
        "nextStep": "Read it after restarting.",
    }

    # First application lifecycle: create the record.
    with TestClient(app) as client:
        response = client.post("/polyps", json=polyp)

        assert response.status_code == 201
        assert response.json() == polyp

    # Second lifecycle: reopen the same database and read it.
    with TestClient(app) as client:
        response = client.get("/polyps")

        assert response.status_code == 200
        assert response.json() == [polyp]