from app.providers.firebase_provider import FirebaseTokenVerifier, FirebaseNotesRepository
from app.providers.base import NotesRepository, TokenVerifier

def get_verifier() -> TokenVerifier:
    return FirebaseTokenVerifier()

def get_repo() -> NotesRepository:
    return FirebaseNotesRepository()