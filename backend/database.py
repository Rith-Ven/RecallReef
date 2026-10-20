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


# Allow this file to be run directly for setup.
if __name__ == "__main__":
    initialize_database()
    print(f"Database ready at: {DATABASE_PATH}")