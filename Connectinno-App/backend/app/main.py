from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes.notes import router as notes_router

app = FastAPI(title="Notes API (Firebase)", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"], allow_credentials=True
)

@app.get("/health")
def health():
    return {"ok": True}

app.include_router(notes_router)
