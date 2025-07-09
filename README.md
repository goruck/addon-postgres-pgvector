# Home Assistant Add-on: PostgreSQL with pgvector

This repository containes two custom [Home Assistant](https://www.home-assistant.io) add-ons:

1. **postgres_pgvector** that provides:

- ✅ PostgreSQL 17 database
- ✅ Built-in [pgvector](https://github.com/pgvector/pgvector) extension (latest version)
- ✅ Automatic creation of user, database, and extension
- ✅ Optional auto-backup on startup
- ✅ Optional [GPG-encrypted](https://gnupg.org) backups for secure storage

This is designed for use with custom integrations that need vector embedding storage, machine learning metadata, or general PostgreSQL access inside Home Assistant OS (HAOS).

2. **postgres_pgvector_tester** that provides a means to quickly test that **postgres_pgvector** is working as expected in your HAOS installation.

Please refer to the add-ons' documentation for installation and configuration details.