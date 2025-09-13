from fastapi import APIRouter, Depends
from typing import List
from app.models.schemas import NoteCreate, NoteUpdate, NoteOut
from app.dependencies.auth import get_current_user
from app.dependencies.provider import get_repo
from app.services.notes_service import NotesService

router = APIRouter(prefix="/notes", tags=["notes"])

@router.get("", response_model=List[NoteOut])
def list_notes(user=Depends(get_current_user), repo=Depends(get_repo)):
    svc = NotesService(repo)
    return [NoteOut(**n) for n in svc.list(user["uid"])]

@router.post("", response_model=NoteOut, status_code=201)
def create_note(payload: NoteCreate, user=Depends(get_current_user), repo=Depends(get_repo)):
    svc = NotesService(repo)
    created = svc.create(user["uid"], payload.title, payload.content, pinned=payload.pinned)
    return NoteOut(**created)

@router.put("/{note_id}", response_model=NoteOut)
def update_note(note_id: str, payload: NoteUpdate, user=Depends(get_current_user), repo=Depends(get_repo)):
    svc = NotesService(repo)
    updated = svc.update(user["uid"], note_id, payload.model_dump(exclude_unset=True))
    return NoteOut(**updated)

@router.delete("/{note_id}", status_code=204)
def delete_note(note_id: str, user=Depends(get_current_user), repo=Depends(get_repo)):
    svc = NotesService(repo)
    svc.delete(user["uid"], note_id)
    return
