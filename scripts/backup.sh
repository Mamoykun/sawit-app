#!/usr/bin/env bash
# Sawitku — PostgreSQL backup script
# Usage:
#   ./scripts/backup.sh             # dump ke ./backups/
#   ./scripts/backup.sh restore <file>  # restore dari file dump
#
# Jalankan via cron di host:
#   0 2 * * * /opt/sawitku/scripts/backup.sh >> /var/log/sawitku-backup.log 2>&1

set -euo pipefail

COMPOSE_PROJECT="sawitku"
CONTAINER="sawitku-postgres"
BACKUP_DIR="$(cd "$(dirname "$0")/.." && pwd)/backups"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

# Load .env kalau ada (untuk POSTGRES_USER / POSTGRES_DB)
if [[ -f "$(dirname "$0")/../.env" ]]; then
  # shellcheck disable=SC1091
  source <(grep -v '^#' "$(dirname "$0")/../.env" | grep -v '^$' | sed 's/^/export /')
fi

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-sawitku_db}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_FILE="$BACKUP_DIR/${POSTGRES_DB}_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

case "${1:-backup}" in
  backup)
    echo "[$(date)] Mulai backup $POSTGRES_DB → $DUMP_FILE"
    docker exec "$CONTAINER" \
      pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-password \
      | gzip > "$DUMP_FILE"
    echo "[$(date)] Backup selesai: $(du -sh "$DUMP_FILE" | cut -f1)"

    # Hapus backup lama
    find "$BACKUP_DIR" -name "${POSTGRES_DB}_*.sql.gz" \
      -mtime +"$RETENTION_DAYS" -delete
    echo "[$(date)] Backup lama (>${RETENTION_DAYS} hari) dihapus"
    ;;

  restore)
    RESTORE_FILE="${2:-}"
    if [[ -z "$RESTORE_FILE" ]]; then
      echo "ERROR: Tentukan file backup. Contoh: $0 restore backups/sawitku_db_20250101_020000.sql.gz"
      exit 1
    fi
    if [[ ! -f "$RESTORE_FILE" ]]; then
      echo "ERROR: File tidak ditemukan: $RESTORE_FILE"
      exit 1
    fi

    echo "[$(date)] PERINGATAN: Restore akan MENGHAPUS data $POSTGRES_DB saat ini!"
    read -r -p "Ketik 'yes' untuk lanjut: " confirm
    [[ "$confirm" != "yes" ]] && { echo "Dibatalkan."; exit 0; }

    echo "[$(date)] Mulai restore dari $RESTORE_FILE"
    gunzip -c "$RESTORE_FILE" | docker exec -i "$CONTAINER" \
      psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
    echo "[$(date)] Restore selesai."
    ;;

  list)
    echo "Daftar backup di $BACKUP_DIR:"
    ls -lh "$BACKUP_DIR"/${POSTGRES_DB}_*.sql.gz 2>/dev/null || echo "(tidak ada backup)"
    ;;

  *)
    echo "Usage: $0 [backup|restore <file>|list]"
    exit 1
    ;;
esac
