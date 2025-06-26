# Home Assistant Add-on: PostgreSQL with pgvector

This is a custom [Home Assistant](https://www.home-assistant.io) add-on that provides:

- ✅ PostgreSQL 17 database
- ✅ Built-in [pgvector](https://github.com/pgvector/pgvector) extension (latest version)
- ✅ Automatic creation of user, database, and extension
- ✅ Optional auto-backup on startup
- ✅ Optional [GPG-encrypted](https://gnupg.org) backups for secure storage

Designed for use with custom integrations that need vector embedding storage, machine learning metadata, or general PostgreSQL access inside Home Assistant OS (HAOS).

---

## 📦 Features

- Runs PostgreSQL 17 inside a secure HAOS-compatible container
- Automatically creates:
  - User: `ha_user`
  - Database: `ha_db`
  - Extension: `pgvector`
- Configurable password via add-on UI
- Optional GPG-encrypted backups to `/backup` or `/share`

---

## 📁 File Structure

```
postgres_pgvector/
├── Dockerfile           # Builds PostgreSQL 17 + pgvector
├── config.json          # HA add-on metadata and options
├── run.sh               # Startup logic and setup automation
├── init.sql             # (unused placeholder)
├── postgresql.conf      # Listens on all interfaces, socket to /tmp
└── pg_hba.conf          # Password (trust/md5) auth config
```

---

## 🚀 Installation

1. SSH or Samba into your Home Assistant OS.
2. Create an `addons` folder if it doesn’t exist.
3. Extract this repository into `addons/postgres_pgvector/`.
4. Go to **Settings → Add-ons → Add-on Store → ⋮ → Reload**.
5. You will see **PostgreSQL with pgvector** under “Local add-ons.”

---

## ⚙️ Configuration Options

After installing, go to the **Configuration** tab and set:

```yaml
ha_user_password: "<your-secure-password>" # Required, must change from default
auto_backup: true # Optional
backup_encrypt: true # Optional
gpg_recipient: "you@example.com" # Required if encryption is on
```

> ❗ **Important**: In your `config.json`, make sure `"host_network": true` appears _before_ the `"ports"` block. Supervisor reads that order strictly.

---

## 🔑 Using pgvector

In your custom integration:

```python
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql+psycopg2://ha_user:<password>@localhost:5432/ha_db"
)
```

To store vector data:

```sql
CREATE TABLE embeddings (
  id SERIAL PRIMARY KEY,
  label TEXT,
  embedding VECTOR(512)
);
```

Querying with cosine similarity:

```sql
SELECT label
  FROM embeddings
 ORDER BY embedding <-> '[0.1, 0.2, ...]'
 LIMIT 5;
```

---

## 🔐 Backup Encryption (Optional)

To encrypt backups using GPG:

- Set `backup_encrypt: true`
- Set `gpg_recipient` to an imported public key (must be in container or volume)
- Add your GPG key via the Terminal add-on:
  ```bash
  gpg --import /path/to/public.key
  ```
  Encrypted backups will be saved as `.sql.gpg` files in `/backup`.

---

## 🧼 Retention Policy

- The last **5 backups** are kept
- Older ones are automatically deleted on startup

---

## 🛠️ Troubleshooting

- ❌ **Add-on won’t start**: Make sure `ha_user_password` is not the default.
- ❌ **Port not exposed**: Confirm `"host_network": true` is above `"ports": { "5432/tcp": 5432 }`.
- ❌ **TCP connections refused**: Ensure `listen_addresses = '*'` in `postgresql.conf` and `pg_hba.conf` allows `host all all 0.0.0.0/0 trust`.

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.

---

## 🤝 Contributions Welcome

PRs and issues are welcome! You can extend this to support:

- Remote database restore
- Scheduled backups
- Multiple database/user support
