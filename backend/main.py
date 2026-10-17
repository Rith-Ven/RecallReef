from fastapi import FastAPI

app = FastAPI(title="Recall Reef API")


@app.get("/health")
def check_health():
    return {"status": "ok"}
