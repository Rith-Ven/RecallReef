import sqlite3
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from pydantic import BaseModel, Field, SecretStr, field_validator
from pwdlib import PasswordHash

from database import (
    insert_user_row,
    fetch_user_by_username,
    insert_auth_token,
    fetch_user_for_token,
    delete_auth_token,
)
import hashlib
import secrets
import time

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

# Reuse registration's credential validation and normalization.
class LoginRequest(RegisterRequest):
    pass

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


TOKEN_LIFETIME_SECONDS = 24 * 60 * 60

# Allow a password verification even when the username is unknown.
DUMMY_PASSWORD_HASH = password_hasher.hash(
    "dummy-value-used-only-for-verification"
)


# Read an Authorization: Bearer ... header.
bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
):
    authentication_error = HTTPException(
        status_code=401,
        detail="Invalid or expired authentication token.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if credentials is None:
        raise authentication_error

    # Hash the submitted token using the same method as login.
    token_hash = hashlib.sha256(
        credentials.credentials.encode("utf-8")
    ).hexdigest()

    user = fetch_user_for_token(
        token_hash,
        int(time.time()),
    )

    if user is None:
        raise authentication_error

    return user

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

@router.post("/login", response_model=TokenResponse)
def login(credentials: LoginRequest) -> TokenResponse:
    user = fetch_user_by_username(credentials.username)

    # Use a dummy hash if the username wasn't found.
    stored_hash = (
        user["password_hash"]
        if user is not None
        else DUMMY_PASSWORD_HASH
    )

    password_matches = password_hasher.verify(
        credentials.password.get_secret_value(),
        stored_hash,
    )

    # Use the same message for an unknown username or wrong password.
    if user is None or not password_matches:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Generate an unpredictable token using secure randomness.
    token = secrets.token_urlsafe(32)

    # Store only its hash so the database doesn't contain usable tokens.
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()

    expires_at = int(time.time()) + TOKEN_LIFETIME_SECONDS

    insert_auth_token(
        token_hash,
        user["id"],
        expires_at,
    )

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=TOKEN_LIFETIME_SECONDS,
    )

@router.get("/me", response_model=UserResponse)
def get_my_account(
    user: dict = Depends(get_current_user),
) -> UserResponse:
    # Return the identity verified by the authentication dependency.
    return UserResponse(
        id=user["id"],
        username=user["username"],
    )

@router.post("/logout", status_code=204)
def logout(
    user: dict = Depends(get_current_user),
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> Response:
    # Authentication must succeed before this function runs.
    token_hash = hashlib.sha256(
        credentials.credentials.encode("utf-8")
    ).hexdigest()

    delete_auth_token(token_hash, user["id"])

    # Successful logout has no response body.
    return Response(status_code=204)