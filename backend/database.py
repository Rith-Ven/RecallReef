import sqlite3
from pathlib import Path

# Add a connection helper
from contextlib import contextmanager

# Keep the database beside this Python file.
#Finds the directory containing database.py, regardless of where Terminal is currently located.
DATABASE_PATH = Path(__file__).resolve().parent / "recallreef.db" # builds db file path  


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

def fetch_polyp_rows():
    with database_connection() as connection:
        # Read the stored fields in a predictable order.
        rows = connection.execute("""
            SELECT id, task_title, stopping_point, next_step
            FROM polyps
            ORDER BY rowid
        """).fetchall()

        # Return ordinary dictionaries, independent of the connection.
        return [dict(row) for row in rows]


def insert_polyp_row(
    polyp_id: str,
    task_title: str,
    stopping_point: str,
    next_step: str,
):
    with database_connection() as connection:
        # Bind values separately from the SQL statement.
        connection.execute("""
            INSERT INTO polyps (
                id, task_title, stopping_point, next_step
            )
            VALUES (?, ?, ?, ?)
        """, (polyp_id, task_title, stopping_point, next_step))


def update_polyp_row(
    polyp_id: str,
    task_title: str,
    stopping_point: str,
    next_step: str,
) -> bool:
    with database_connection() as connection:
        # Update only the record with this ID.
        cursor = connection.execute("""
            UPDATE polyps
            SET task_title = ?, stopping_point = ?, next_step = ?
            WHERE id = ?
        """, (task_title, stopping_point, next_step, polyp_id))

        # False means no matching record exists.
        return cursor.rowcount > 0

def delete_polyp_row(polyp_id: str) -> bool:
    with database_connection() as connection:
        # Delete only the row with the supplied ID.
        cursor = connection.execute(
            "DELETE FROM polyps WHERE id = ?",
            (polyp_id,),
        )

        # True means a matching row was removed.
        return cursor.rowcount > 0

# Save a focus session.
def insert_focus_session_row(
    session_id: str,
    polyp_id: str,
    task_title: str,
    started_at: str,
    focused_seconds: int,
    completed_full_timer: bool,
):
    with database_connection() as connection:
        # Insert one historical session, preserving its original ID.
        connection.execute("""
            INSERT INTO focus_sessions (
                id,
                polyp_id,
                task_title,
                started_at,
                focused_seconds,
                completed_full_timer
            )
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            session_id,
            polyp_id,
            task_title,
            started_at,
            focused_seconds,
            int(completed_full_timer),
        ))

# Read a focus session.
def fetch_focus_session_rows(polyp_id: str | None = None):
    with database_connection() as connection:
        query = """
            SELECT
                id,
                polyp_id,
                task_title,
                started_at,
                focused_seconds,
                completed_full_timer
            FROM focus_sessions
        """

        parameters = ()

        # Apply an optional filter using a bound parameter.
        if polyp_id is not None:
            query += " WHERE polyp_id = ?"
            parameters = (polyp_id,)

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

# Allow this file to be run directly for setup.
if __name__ == "__main__":
    initialize_database()
    print(f"Database ready at: {DATABASE_PATH}")