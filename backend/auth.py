import sqlite3
from uuid import UUID, uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, SecretStr, field_validator
from pwdlib import PasswordHash

from database import insert_user_row

# Group account endpoints under /auth.
router = APIRouter(prefix="/auth", tags=["Accounts"])

# Use the library's recommended Argon2 password hasher.
password_hasher = PasswordHash.recommended()


class RegisterRequest(BaseModel):
    username: str = Field(
        min_length=3,
        max_length=40,
        pattern=r"^[A-Za-z0-9_]+$",
    )
    password: SecretStr = Field(min_length=12, max_length=128)

    @field_validator("username")
    @classmethod
    def normalize_username(cls, value: str) -> str:
        # Treat uppercase and lowercase usernames as the same.
        return value.lower()


class UserResponse(BaseModel):
    # Only these public fields may appear in the response.
    id: UUID
    username: str


@router.post("/register", status_code=201, response_model=UserResponse)
def register(credentials: RegisterRequest) -> UserResponse:
    user_id = uuid4()

    # Extract the password only when passing it to the hasher.
    password_hash = password_hasher.hash(
        credentials.password.get_secret_value()
    )

    try:
        insert_user_row(
            str(user_id),
            credentials.username,
            password_hash,
        )
    except sqlite3.IntegrityError as error:
        # The database enforces unique usernames.
        if error.sqlite_errorcode == sqlite3.SQLITE_CONSTRAINT_UNIQUE:
            raise HTTPException(
                status_code=409,
                detail="Username unavailable.",
            ) from error

        raise

    return UserResponse(
        id=user_id,
        username=credentials.username,
    )