import sqlite3
from pathlib import Path

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


# Allow this file to be run directly for setup.
if __name__ == "__main__":
    initialize_database()
    print(f"Database ready at: {DATABASE_PATH}")