from typing import List, Dict, Any
from datetime import datetime, timezone
from fastapi import HTTPException, status
import os

import firebase_admin
from firebase_admin import credentials, auth as fb_auth
from google.cloud import firestore

from app.core.config import GOOGLE_APPLICATION_CREDENTIALS, FIREBASE_PROJECT_ID
from app.providers.base import NotesRepository, TokenVerifier

# Init Firebase Admin once
if not firebase_admin._apps:
    if not GOOGLE_APPLICATION_CREDENTIALS or not os.path.isfile(GOOGLE_APPLICATION_CREDENTIALS):
        raise RuntimeError("GOOGLE_APPLICATION_CREDENTIALS must point to a valid service account file.")
    firebase_admin.initialize_app(credentials.Certificate(GOOGLE_APPLICATION_CREDENTIALS))

db = firestore.Client(project=FIREBASE_PROJECT_ID)

def _notes_col(uid: str):
    return db.collection("users").document(uid).collection("notes")

class FirebaseTokenVerifier(TokenVerifier):
    def verify(self, authorization_header: str) -> dict:
        if not authorization_header or not authorization_header.lower().startswith("bearer "):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing/invalid Authorization header")
        token = authorization_header.split(" ", 1)[1]
        try:
            decoded = fb_auth.verify_id_token(token)
            return decoded
        except Exception:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

class FirebaseNotesRepository(NotesRepository):
    
    def list_notes(self, uid: str):
        docs = _notes_col(uid).stream()
        notes = []
        for d in docs:
            data = d.to_dict()
            notes.append({
                "id": d.id,
                "title": data["title"],
                "content": data.get("content", ""),
                "pinned": data.get("pinned", False),
                "created_at": data["created_at"],
                "updated_at": data["updated_at"],
            })
        # stable sort: newest first, then pinned to top
        notes.sort(key=lambda n: n["created_at"], reverse=True)
        notes.sort(key=lambda n: not n["pinned"])
        return notes


    def create_note(self, uid: str, title: str, content: str, pinned: bool = False) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        ref = _notes_col(uid).document()
        doc = {
            "title": title,
            "content": content,
            "pinned": pinned,                               # store pinned
            "created_at": now,
            "updated_at": now,
        }
        ref.set(doc)
        return {"id": ref.id, **doc}

    def update_note(self, uid: str, note_id: str, patch: Dict[str, Any]) -> Dict[str, Any]:
        ref = _notes_col(uid).document(note_id)
        snap = ref.get()
        if not snap.exists:
            raise HTTPException(status_code=404, detail="Note not found")
        patch = {k: v for k, v in patch.items() if v is not None}
        if patch:
            patch["updated_at"] = datetime.now(timezone.utc)
            ref.update(patch)
        data = ref.get().to_dict()
        return {"id": note_id, **data}

    def delete_note(self, uid: str, note_id: str) -> None:
        ref = _notes_col(uid).document(note_id)
        if not ref.get().exists:
            raise HTTPException(status_code=404, detail="Note not found")
        ref.delete()
