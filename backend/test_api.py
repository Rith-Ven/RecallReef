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
        authorize_test_client(client)
        response = client.post("/polyps", json=polyp)

        assert response.status_code == 201
        assert response.json() == polyp

    # Second lifecycle: reopen the same database and read it.
    with TestClient(app) as client:
        authorize_test_client(client)
        response = client.get("/polyps")

        assert response.status_code == 200
        assert response.json() == [polyp]


def test_session_persistence_and_validation(tmp_path, monkeypatch):
    # Isolate this test from real records and other tests.
    test_database = tmp_path / "test_sessions.db"
    monkeypatch.setattr(database, "DATABASE_PATH", test_database)

    session = {
        "id": "739e0c2b-c1dc-4fa8-a832-07ce3daea8d0",
        "polypID": "b39b036c-4158-4d79-a263-8d573156f728",
        "taskTitle": "Study Swift",
        "startedAt": "2026-10-20T14:00:00Z",
        "focusedSeconds": 300,
        "completedFullTimer": False,
    }

    with TestClient(app) as client:
        authorize_test_client(client)
        # A new session should be accepted.
        created = client.post("/sessions", json=session)
        assert created.status_code == 201

        # Preserve the server's timestamp representation for comparison.
        saved_session = created.json()

        # The same session ID must not create another record.
        duplicate = client.post("/sessions", json=session)
        assert duplicate.status_code == 409

        # Give invalid input its own ID to isolate duration validation.
        invalid_session = {
            **session,
            "id": "8ef7e53b-b296-42bb-a903-33546bcf6782",
            "focusedSeconds": -5,
        }

        invalid = client.post("/sessions", json=invalid_session)
        assert invalid.status_code == 422

        # Neither rejected request should add a row.
        history = client.get("/sessions")
        assert history.status_code == 200
        assert history.json() == [saved_session]

    # Reopen the application using the same temporary database.
    with TestClient(app) as client:
        history = client.get("/sessions")
        assert history.status_code == 200
        assert history.json() == [saved_session]

def test_sessions_are_sorted_by_actual_start_time(tmp_path, monkeypatch):
    # Use a separate database for this test.
    monkeypatch.setattr(
        database,
        "DATABASE_PATH",
        tmp_path / "session_order.db",
    )

    earlier_session = {
        "id": "6c5b48dc-917a-4e16-8d34-1ed92dca5a51",
        "polypID": "b39b036c-4158-4d79-a263-8d573156f728",
        "taskTitle": "Earlier session",
        "startedAt": "2026-10-21T14:00:00+02:00",
        "focusedSeconds": 300,
        "completedFullTimer": False,
    }

    later_session = {
        **earlier_session,
        "id": "ac519c06-8b3d-44b0-a1fd-f9c1f4fba802",
        "taskTitle": "Later session",
        "startedAt": "2026-10-21T13:00:00Z",
    }

    with TestClient(app) as client:
        authorize_test_client(client)
        # Upload the earlier record first.
        first = client.post("/sessions", json=earlier_session)
        second = client.post("/sessions", json=later_session)

        assert first.status_code == 201
        assert second.status_code == 201

        response = client.get("/sessions")
        assert response.status_code == 200

        # History must place the later moment first.
        returned_ids = [session["id"] for session in response.json()]

        assert returned_ids == [
            later_session["id"],
            earlier_session["id"],
        ]

# Authenticate a test client against its temporary database.
def authorize_test_client(client):
    credentials = {
        "username": "test_learner",
        "password": "Testing-Reefs-2026!",
    }

    registered = client.post("/auth/register", json=credentials)
    assert registered.status_code in (201, 409)

    logged_in = client.post("/auth/login", json=credentials)
    assert logged_in.status_code == 200

    token = logged_in.json()["access_token"]
    client.headers["Authorization"] = f"Bearer {token}"