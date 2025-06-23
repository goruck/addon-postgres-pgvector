#!/usr/bin/with-contenv bashio
set -e

DATA_DIR="/data/pgdata"
SQL_TEMPLATE="/init.sql.j2"
SQL_FINAL="/tmp/init.sql"
BACKUP_DIR="/backup"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/ha_db_$DATE.sql"
ENCRYPTED_FILE="$BACKUP_FILE.gpg"

if [ ! -d "$DATA_DIR" ]; then
    bashio::log.info "Initializing PostgreSQL data directory..."
    su postgres -c "initdb -D $DATA_DIR"
fi

bashio::log.info "Copying config..."
cp /etc/postgresql/postgresql.conf $DATA_DIR/postgresql.conf
cp /etc/postgresql/pg_hba.conf $DATA_DIR/pg_hba.conf

bashio::log.info "Starting PostgreSQL for setup and checks..."
su postgres -c "/usr/bin/postgres -D $DATA_DIR -c config_file=$DATA_DIR/postgresql.conf" &
sleep 5

HA_PASS=$(bashio::config 'ha_user_password')
if [ "$HA_PASS" == "ChangeThisSecurePassword" ]; then
    bashio::exit.nok "You must change the ha_user_password from the default!"
fi
sed "s/{{ ha_user_password }}/$HA_PASS/g" "$SQL_TEMPLATE" > "$SQL_FINAL"

bashio::log.info "Running DB/user/pgvector setup..."
su postgres -c "psql -f $SQL_FINAL"
rm -f "$SQL_FINAL"

if bashio::config.true 'auto_backup'; then
    bashio::log.info "Performing database backup..."
    mkdir -p "$BACKUP_DIR"
    su postgres -c "pg_dump ha_db > $BACKUP_FILE"

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
