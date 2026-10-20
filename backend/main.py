import sqlite3
from contextlib import asynccontextmanager
from uuid import UUID

from fastapi import FastAPI, HTTPException, Response
from pydantic import AwareDatetime, BaseModel, Field
from datetime import timezone

from database import (
    initialize_database,
    fetch_polyp_rows,
    insert_polyp_row,
    update_polyp_row,
    delete_polyp_row,
    fetch_focus_session_rows,
    insert_focus_session_row,
)


# Prepare the database before accepting requests.
@asynccontextmanager
async def lifespan(app: FastAPI):
    initialize_database()
    yield


app = FastAPI(title="Recall Reef API", lifespan=lifespan)


# Keep the existing JSON format expected by Swift.
class CoralPolyp(BaseModel):
    id: UUID
    taskTitle: str
    stoppingPoint: str
    nextStep: str

# Describe a completed focus attempt.
class FocusSession(BaseModel):
    id: UUID
    polypID: UUID
    taskTitle: str
    startedAt: AwareDatetime

    # Focused time cannot be negative.
    focusedSeconds: int = Field(ge=0)

    completedFullTimer: bool

# Share title validation between creation and updates.
def validate_title(polyp: CoralPolyp):
    polyp.taskTitle = polyp.taskTitle.strip()

    if not polyp.taskTitle:
        raise HTTPException(
            status_code=422,
            detail="Task title must not be blank.",
        )


@app.get("/health")
def check_health():
    return {"status": "ok"}


@app.get("/polyps")
def get_polyps() -> list[CoralPolyp]:
    rows = fetch_polyp_rows()

    # Map database column names to the API's field names.
    return [
        CoralPolyp(
            id=row["id"],
            taskTitle=row["task_title"],
            stoppingPoint=row["stopping_point"],
            nextStep=row["next_step"],
        )
        for row in rows
    ]


@app.post("/polyps", status_code=201)
def create_polyp(polyp: CoralPolyp) -> CoralPolyp:
    validate_title(polyp)

    try:
        # SQLite stores the UUID as text.
        insert_polyp_row(
            str(polyp.id),
            polyp.taskTitle,
            polyp.stoppingPoint,
            polyp.nextStep,
        )
    except sqlite3.IntegrityError as error:
        # Translate a duplicate primary key into an HTTP conflict.
        if error.sqlite_errorcode == sqlite3.SQLITE_CONSTRAINT_PRIMARYKEY:
            raise HTTPException(
                status_code=409,
                detail="A polyp with this ID already exists.",
            ) from error

        # Other constraint failures are unexpected server errors.
        raise

    return polyp


@app.put("/polyps/{polyp_id}")
def update_polyp(polyp_id: UUID, polyp: CoralPolyp) -> CoralPolyp:
    if polyp_id != polyp.id:
        raise HTTPException(
            status_code=422,
            detail="The URL ID and polyp ID must match.",
        )

    validate_title(polyp)

    # The helper reports whether a matching row was found.
    was_updated = update_polyp_row(
        str(polyp_id),
        polyp.taskTitle,
        polyp.stoppingPoint,
        polyp.nextStep,
    )

    if not was_updated:
        raise HTTPException(
            status_code=404,
            detail="No polyp with this ID exists.",
        )

    return polyp



# Handle DELETE requests for one backend polyp.
@app.delete("/polyps/{polyp_id}", status_code=204)
def delete_polyp(polyp_id: UUID) -> Response:
    was_deleted = delete_polyp_row(str(polyp_id))

    if not was_deleted:
        raise HTTPException(
            status_code=404,
            detail="No polyp with this ID exists.",
        )

    # Success with no response body.
    return Response(status_code=204)


@app.get("/sessions")
def get_sessions() -> list[FocusSession]:
    rows = fetch_focus_session_rows()

    # Translate database columns into API fields.
    sessions = [
        FocusSession(
            id=row["id"],
            polypID=row["polyp_id"],
            taskTitle=row["task_title"],
            startedAt=row["started_at"],
            focusedSeconds=row["focused_seconds"],
            completedFullTimer=bool(row["completed_full_timer"]),
        )
        for row in rows
    ]

    # Return newest sessions first, based on their actual start time.
    return sorted(
        sessions,
        key=lambda session: session.startedAt,
        reverse=True,
    )

@app.post("/sessions", status_code=201)
def create_session(session: FocusSession) -> FocusSession:
    # Preserve a readable historical task title.
    session.taskTitle = session.taskTitle.strip()

    if not session.taskTitle:
        raise HTTPException(
            status_code=422,
            detail="Task title must not be blank.",
        )

    # Normalize timestamps to UTC before storing them.
    session.startedAt = session.startedAt.astimezone(timezone.utc)

    try:
        insert_focus_session_row(
            str(session.id),
            str(session.polypID),
            session.taskTitle,
            session.startedAt.isoformat(),
            session.focusedSeconds,
            session.completedFullTimer,
        )
    except sqlite3.IntegrityError as error:
        # Reject uploading the same session record twice.
        if error.sqlite_errorcode == sqlite3.SQLITE_CONSTRAINT_PRIMARYKEY:
            raise HTTPException(
                status_code=409,
                detail="A session with this ID already exists.",
            ) from error

        raise

    return session