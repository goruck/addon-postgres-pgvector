import psycopg
import time

for attempt in range(10):
    try:
        conn = psycopg.connect(
            dbname="ha_db",
            user="ha_user",
            host="127.0.0.1",
            port=5432,
            connect_timeout=2
        )
        break
    except psycopg.OperationalError as e:
        print(f"Attempt {attempt+1}/10: PostgreSQL not ready. Retrying...")
        time.sleep(3)
else:
    raise RuntimeError("Failed to connect to PostgreSQL after 10 attempts")

with conn.cursor() as cur:
    cur.execute("SELECT extname FROM pg_extension WHERE extname = 'vector'")
    assert cur.fetchone(), "pgvector extension is not installed."

    cur.execute("DROP TABLE IF EXISTS items")
    cur.execute("CREATE TABLE items (id serial PRIMARY KEY, embedding vector(3))")
    cur.execute("INSERT INTO items (embedding) VALUES ('[1, 2, 3]')")

    cur.execute("SELECT embedding FROM items")
    print("Retrieved vector:", cur.fetchone()[0])

    cur.execute("INSERT INTO items (embedding) VALUES ('[1, 0, 0]'), ('[0, 1, 0]')")
    cur.execute("""
        SELECT id, embedding <-> '[1, 2, 3]' AS distance
        FROM items
        ORDER BY distance ASC
        LIMIT 1
    """)
    result = cur.fetchone()
    print("Most similar vector ID:", result[0], "Distance:", result[1])

conn.commit()
conn.close()