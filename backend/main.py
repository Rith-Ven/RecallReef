from uuid import UUID

from fastapi import FastAPI
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
        taskTitle="Study Swift",
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