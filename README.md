# Home Assistant Add-on: PostgreSQL with pgvector

This is a custom [Home Assistant](https://www.home-assistant.io) add-on that provides:

- ✅ PostgreSQL 16 database
- ✅ Built-in [pgvector](https://github.com/pgvector/pgvector) extension (latest version)
- ✅ Automatic creation of user, database, and extension
- ✅ Optional auto-backup on startup
- ✅ Optional [GPG-encrypted](https://gnupg.org) backups for secure storage

Designed for use with custom integrations that need vector embedding storage, machine learning metadata, or general PostgreSQL access inside Home Assistant OS (HAOS).

---

## 📦 Features

- Runs PostgreSQL 16 inside a secure HAOS-compatible container
- Automatically creates:
  - User: `ha_user`
  - Database: `ha_db`
  - Extension: `pgvector`
- Configurable password via add-on UI
- Optional GPG-encrypted backups to `/backup` or `/share`

---

## 📁 File Structure

This add-on includes the following files:

```
postgres_pgvector/
├── Dockerfile           # Builds PostgreSQL 16 + pgvector
├── config.json          # HA add-on metadata and options
├── run.sh               # Startup logic and setup automation
├── init.sql.j2          # Dynamic SQL template with password injection
├── postgresql.conf      # Listens on all interfaces
└── pg_hba.conf          # Password authentication for all clients
```

---

## 🚀 Installation

1. SSH or Samba into your Home Assistant OS.
2. Create an `addons` folder if it doesn't exist.
3. Extract this repository into `addons/postgres_pgvector/`.
4. Go to **Settings → Add-ons → Add-on Store → ⋮ → Reload**.
5. You will see **PostgreSQL with pgvector** under “Local add-ons.”

---

## ⚙️ Configuration Options

After installing, go to the **Configuration** tab and set:

```yaml
ha_user_password: "<your-secure-password>"   # Required
auto_backup: true                            # Optional
backup_encrypt: true                         # Optional
gpg_recipient: "your@email.com"              # Required if encryption is on
```

> ❗ You **must change** the default password before the add-on will start.

---

## 🔑 Using pgvector

In your custom integration:

```python
engine = create_engine("postgresql+psycopg2://ha_user:<password>@localhost:5432/ha_db")
```

To store vector data:

```sql
CREATE TABLE embeddings (
  id SERIAL PRIMARY KEY,
  label TEXT,
  embedding vector(512)
);
```

Querying with cosine similarity:

```sql
SELECT label FROM embeddings ORDER BY embedding <-> '[0.1, 0.2, ...]' LIMIT 5;
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

- ❌ `You must change the ha_user_password`: Set a custom password in the Configuration tab.
- ❌ `GPG encryption enabled but no recipient provided`: Set `gpg_recipient` or disable encryption.
- Backups not appearing? Ensure `/backup` is writable and mapped correctly.

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- [pgvector](https://github.com/pgvector/pgvector)
- [Home Assistant Add-on Docs](https://developers.home-assistant.io/docs/add-ons/)

---

## 🤝 Contributions Welcome

PRs and issues are welcome! You can extend this to support:
- Remote database restore
- Scheduled backups
- Multiple database/user support
