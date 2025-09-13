from typing import List, Dict, Any
from app.providers.base import NotesRepository

class NotesService:
    def __init__(self, repo: NotesRepository):
        self.repo = repo

    def list(self, uid: str) -> List[Dict[str, Any]]:
        return self.repo.list_notes(uid)

    def create(self, uid: str, title: str, content: str, pinned: bool = False) -> Dict[str, Any]:
        return self.repo.create_note(uid, title, content, pinned=pinned)

    def update(self, uid: str, note_id: str, patch: Dict[str, Any]) -> Dict[str, Any]:
        return self.repo.update_note(uid, note_id, patch)

    def delete(self, uid: str, note_id: str) -> None:
        self.repo.delete_note(uid, note_id)
