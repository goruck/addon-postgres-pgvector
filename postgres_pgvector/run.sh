#!/usr/bin/with-contenv bashio
set -e

DATA_DIR="/data/pgdata"
SQL_TEMPLATE="/init.sql.j2"
SQL_USER_SQL="/tmp/init_user.sql"
SQL_EXT_SQL="/tmp/init_pgvector.sql"
BACKUP_DIR="/backup"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/ha_db_$DATE.sql"
ENCRYPTED_FILE="$BACKUP_FILE.gpg"

# Ensure /data/pgdata exists and is owned by postgres
if [ ! -d "$DATA_DIR" ]; then
    bashio::log.info "Creating and preparing data directory..."
    mkdir -p "$DATA_DIR"
    chown -R postgres:postgres "$DATA_DIR"
fi

# Initialize DB if not already initialized
if [ ! -f "$DATA_DIR/PG_VERSION" ]; then
    bashio::log.info "Initializing PostgreSQL data directory..."
    su postgres -c "initdb -D $DATA_DIR"
fi

bashio::log.info "Copying config..."
rm -f $DATA_DIR/postgresql.conf $DATA_DIR/pg_hba.conf
cp /etc/postgresql/postgresql.conf $DATA_DIR/
cp /etc/postgresql/pg_hba.conf $DATA_DIR/
chown postgres:postgres $DATA_DIR/*.conf

bashio::log.info "Starting PostgreSQL for setup and checks..."
su postgres -c "/usr/bin/postgres -D $DATA_DIR -c config_file=$DATA_DIR/postgresql.conf" &

# Wait until ready
until su postgres -c "pg_isready -q -h /tmp"; do
    bashio::log.info "Waiting for PostgreSQL via Unix socket at /tmp..."
    sleep 1
done

# Extract password from config
HA_PASS=$(bashio::config 'ha_user_password')
if [ "$HA_PASS" == "ChangeThisSecurePassword" ]; then
    bashio::exit.nok "You must change the ha_user_password from the default!"
fi

# Generate SQL for user creation
sed "s/{{ ha_user_password }}/$HA_PASS/g" "$SQL_TEMPLATE" > "$SQL_USER_SQL"
echo "CREATE EXTENSION IF NOT EXISTS vector;" > "$SQL_EXT_SQL"

# Run user creation
bashio::log.info "Creating user..."
su postgres -c "psql -h /tmp -d postgres -f $SQL_USER_SQL"

# Check if database exists and create if needed
if ! su postgres -c "psql -h /tmp -d postgres -tAc \"SELECT 1 FROM pg_database WHERE datname = 'ha_db'\"" | grep -q 1; then
    bashio::log.info "Creating database ha_db..."
    su postgres -c "createdb -h /tmp -O ha_user ha_db"
fi

# Run pgvector extension setup
bashio::log.info "Enabling pgvector in ha_db..."
su postgres -c "psql -h /tmp -d ha_db -f $SQL_EXT_SQL"

# Cleanup
rm -f "$SQL_USER_SQL" "$SQL_EXT_SQL"

# Optional backup
if bashio::config.true 'auto_backup'; then
    bashio::log.info "Performing database backup..."
    mkdir -p "$BACKUP_DIR"
    chown -R postgres:postgres "$BACKUP_DIR"
    su postgres -c "pg_dump -h /tmp -d ha_db > $BACKUP_FILE"


    if bashio::config.true 'backup_encrypt'; then
        RECIPIENT=$(bashio::config 'gpg_recipient')
        if [ -z "$RECIPIENT" ]; then
            bashio::exit.nok "GPG encryption enabled but no recipient provided."
        fi
        bashio::log.info "Encrypting backup with GPG for recipient: $RECIPIENT"
        gpg --yes --batch --output "$ENCRYPTED_FILE" --encrypt --recipient "$RECIPIENT" "$BACKUP_FILE" && rm -f "$BACKUP_FILE"
    fi

    ls -tp "$BACKUP_DIR"/ha_db_*.sql* | grep -v '/$' | tail -n +6 | xargs -r rm --
fi

wait
