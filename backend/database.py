import sqlite3
from pathlib import Path

# Add a connection helper
from contextlib import contextmanager

# Keep the database beside this Python file.
#Finds the directory containing database.py, regardless of where Terminal is currently located.
DATABASE_PATH = Path(__file__).resolve().parent / "recallreef.db" # builds db file path  

# Add ownership columns while preserving existing rows.
def add_ownership_columns(connection):
    for table in ("polyps", "focus_sessions"):
        columns = connection.execute(
            f"PRAGMA table_info({table})"
        ).fetchall()

        column_names = [column[1] for column in columns]

        if "owner_id" not in column_names:
            connection.execute(
                f"ALTER TABLE {table} "
                "ADD COLUMN owner_id TEXT REFERENCES users(id)"
            )

def initialize_database():
    # Open the database file, creating it if necessary.
    connection = sqlite3.connect(DATABASE_PATH)

    try:
        # Create the table without replacing an existing one.
        connection.execute("""
            CREATE TABLE IF NOT EXISTS polyps (
                id TEXT PRIMARY KEY NOT NULL,
                task_title TEXT NOT NULL,
                stopping_point TEXT NOT NULL,
                next_step TEXT NOT NULL
            )
        """)
        # Store historical sessions separately from editable polyps.
        connection.execute("""
            CREATE TABLE IF NOT EXISTS focus_sessions (
                id TEXT PRIMARY KEY NOT NULL,
                polyp_id TEXT NOT NULL,
                task_title TEXT NOT NULL,
                started_at TEXT NOT NULL,
                focused_seconds INTEGER NOT NULL
                    CHECK (focused_seconds >= 0),
                completed_full_timer INTEGER NOT NULL
                    CHECK (completed_full_timer IN (0, 1))
            )
        """)

        # Store account identities and password hashes.
        connection.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY NOT NULL,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL
            )
        """)

        # Store login tokens separately from focus-session history.
        connection.execute("""
            CREATE TABLE IF NOT EXISTS auth_tokens (
                token_hash TEXT PRIMARY KEY NOT NULL,
                user_id TEXT NOT NULL REFERENCES users(id),
                expires_at INTEGER NOT NULL
            )
        """)

        # Upgrade existing tables without deleting their records.
        add_ownership_columns(connection)

        connection.commit()
    finally:
        # Release the connection even if an operation fails, cleanup operation
        connection.close()


@contextmanager
def database_connection():
    # Open a fresh connection for this operation.
    connection = sqlite3.connect(DATABASE_PATH)

    # Allow reading results by column name.
    connection.row_factory = sqlite3.Row

    # Enforce relationships declared with REFERENCES.
    connection.execute("PRAGMA foreign_keys = ON")

    try:
        # Commit on success; roll back if an exception occurs.
        with connection:
            yield connection
    finally:
        connection.close()

# Fetch only the authenticated account's polyps.
def fetch_polyp_rows(owner_id: str):
    with database_connection() as connection:
        rows = connection.execute("""
            SELECT id, task_title, stopping_point, next_step
            FROM polyps
            WHERE owner_id = ?
            ORDER BY rowid
        """, (owner_id,)).fetchall()

        return [dict(row) for row in rows]


# Create a polyp belonging to the authenticated account.
def insert_polyp_row(
    owner_id: str,
    polyp_id: str,
    task_title: str,
    stopping_point: str,
    next_step: str,
):
    with database_connection() as connection:
        connection.execute("""
            INSERT INTO polyps (
                owner_id, id, task_title, stopping_point, next_step
            )
            VALUES (?, ?, ?, ?, ?)
        """, (
            owner_id, polyp_id, task_title, stopping_point, next_step
        ))


# Update a polyp only when both its owner and ID match.
def update_polyp_row(
    owner_id: str,
    polyp_id: str,
    task_title: str,
    stopping_point: str,
    next_step: str,
) -> bool:
    with database_connection() as connection:
        cursor = connection.execute("""
            UPDATE polyps
            SET task_title = ?, stopping_point = ?, next_step = ?
            WHERE owner_id = ? AND id = ?
        """, (
            task_title, stopping_point, next_step, owner_id, polyp_id
        ))

        return cursor.rowcount > 0


# Delete a polyp only when it belongs to this account.
def delete_polyp_row(owner_id: str, polyp_id: str) -> bool:
    with database_connection() as connection:
        cursor = connection.execute("""
            DELETE FROM polyps
            WHERE owner_id = ? AND id = ?
        """, (owner_id, polyp_id))

        return cursor.rowcount > 0

# Save a focus session.
# Store a focus session belonging to the authenticated account.
def insert_focus_session_row(
    owner_id: str,
    session_id: str,
    polyp_id: str,
    task_title: str,
    started_at: str,
    focused_seconds: int,
    completed_full_timer: bool,
):
    with database_connection() as connection:
        connection.execute("""
            INSERT INTO focus_sessions (
                owner_id,
                id,
                polyp_id,
                task_title,
                started_at,
                focused_seconds,
                completed_full_timer
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            owner_id,
            session_id,
            polyp_id,
            task_title,
            started_at,
            focused_seconds,
            int(completed_full_timer),
        ))

# Read a focus session.
# Fetch this account's history, optionally filtered by polyp.
def fetch_focus_session_rows(
    owner_id: str,
    polyp_id: str | None = None,
):
    with database_connection() as connection:
        query = """
            SELECT
                id, polyp_id, task_title, started_at,
                focused_seconds, completed_full_timer
            FROM focus_sessions
            WHERE owner_id = ?
        """
        parameters = (owner_id,)

        # A task filter supplements ownership; it never replaces it.
        if polyp_id is not None:
            query += " AND polyp_id = ?"
            parameters += (polyp_id,)

        query += " ORDER BY rowid"

        rows = connection.execute(query, parameters).fetchall()
        return [dict(row) for row in rows]

def insert_user_row(user_id: str, username: str, password_hash: str):
    with database_connection() as connection:
        # Store the hash, never the original password.
        connection.execute("""
            INSERT INTO users (id, username, password_hash)
            VALUES (?, ?, ?)
        """, (user_id, username, password_hash))


def fetch_user_by_username(username: str):
    with database_connection() as connection:
        # Login needs the stored hash to verify the supplied password.
        row = connection.execute("""
            SELECT id, username, password_hash
            FROM users
            WHERE username = ?
        """, (username,)).fetchone()

        return dict(row) if row is not None else None


def insert_auth_token(token_hash: str, user_id: str, expires_at: int):
    with database_connection() as connection:
        # Store the verifier, not the reusable token itself.
        connection.execute("""
            INSERT INTO auth_tokens (token_hash, user_id, expires_at)
            VALUES (?, ?, ?)
        """, (token_hash, user_id, expires_at))

# Conencts a token's userid to the corresponding account
def fetch_user_for_token(token_hash: str, current_time: int):
    with database_connection() as connection:
        # Find the account only if its token has not expired.
        row = connection.execute("""
            SELECT users.id, users.username
            FROM auth_tokens
            JOIN users ON users.id = auth_tokens.user_id
            WHERE auth_tokens.token_hash = ?
              AND auth_tokens.expires_at > ?
        """, (token_hash, current_time)).fetchone()

        return dict(row) if row is not None else None

def delete_auth_token(token_hash: str, user_id: str) -> bool:
    with database_connection() as connection:
        # Revoke only this token belonging to this account.
        cursor = connection.execute("""
            DELETE FROM auth_tokens
            WHERE token_hash = ? AND user_id = ?
        """, (token_hash, user_id))

        return cursor.rowcount > 0

# Assign unowned development records to one explicitly chosen account.
def assign_legacy_records(username: str):
    with database_connection() as connection:
        user = connection.execute("""
            SELECT id FROM users WHERE username = ?
        """, (username.lower(),)).fetchone()

        if user is None:
            raise ValueError("Register this account before assigning records.")

        counts = {}

        # These table names are fixed by the code, not supplied by a client.
        for table in ("polyps", "focus_sessions"):
            cursor = connection.execute(
                f"UPDATE {table} SET owner_id = ? WHERE owner_id IS NULL",
                (user["id"],),
            )
            counts[table] = cursor.rowcount

        return counts

# Allow this file to be run directly for setup.
if __name__ == "__main__":
    initialize_database()
    print(f"Database ready at: {DATABASE_PATH}")

