from fastapi import Header
from app.dependencies.provider import get_verifier

def get_current_user(authorization: str | None = Header(default=None)):
    verifier = get_verifier()
    claims = verifier.verify(authorization)
    return {"uid": claims.get("uid"), **claims}
