from uuid import UUID

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Create the API application.
app = FastAPI(title="Recall Reef API")


# Describe the fields in a coral polyp.
class CoralPolyp(BaseModel):
    id: UUID
    taskTitle: str
    stoppingPoint: str
    nextStep: str


# Temporary sample data, independent of the iOS app.
sample_polyps = [
    CoralPolyp(
        id=UUID("d13ad2b0-72c8-4ef7-9316-b91caf386142"),
        taskTitle="Learn how APIs work",
        stoppingPoint="Practiced state and bindings.",
        nextStep="Connect the app to the backend.",
    )
]


# Check that the application can respond.
@app.get("/health")
def check_health():
    return {"status": "ok"}


# Return a collection of coral polyps.
@app.get("/polyps")
def get_polyps() -> list[CoralPolyp]:
    return sample_polyps


# Accept a polyp from the request's JSON body.
@app.post("/polyps", status_code=201)
def create_polyp(polyp: CoralPolyp) -> CoralPolyp:
    # Reject titles that are empty or contain only whitespace.
    polyp.taskTitle = polyp.taskTitle.strip()

    if not polyp.taskTitle:
        raise HTTPException(
            status_code=422,
            detail="Task title must not be blank.",
        )

    # Reject an ID already used by another record.
    for existing_polyp in sample_polyps:
        if existing_polyp.id == polyp.id:
            raise HTTPException(
                status_code=409,
                detail="A polyp with this ID already exists.",
            )

    # Store the record in the server's temporary list.
    sample_polyps.append(polyp)

    # Return the record that was created.
    return polyp


# Replace the editable fields of an existing polyp.
@app.put("/polyps/{polyp_id}")
def update_polyp(polyp_id: UUID, polyp: CoralPolyp) -> CoralPolyp:
    # The URL and body must identify the same record.
    if polyp_id != polyp.id:
        raise HTTPException(
            status_code=422,
            detail="The URL ID and polyp ID must match.",
        )

    polyp.taskTitle = polyp.taskTitle.strip()

    if not polyp.taskTitle:
        raise HTTPException(
            status_code=422,
            detail="Task title must not be blank.",
        )

    # Replace the matching record in the temporary collection.
    for index, existing_polyp in enumerate(sample_polyps):
        if existing_polyp.id == polyp_id:
            sample_polyps[index] = polyp
            return polyp

    raise HTTPException(
        status_code=404,
        detail="No polyp with this ID exists.",
    )