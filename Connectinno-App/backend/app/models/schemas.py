from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class NoteCreate(BaseModel):
    title: str
    content: str = ""
    pinned: bool = False   # NEW

class NoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    pinned: Optional[bool] = None   # NEW

class NoteOut(BaseModel):
    id: str
    title: str
    content: str
    pinned: bool
    created_at: datetime
    updated_at: datetime
