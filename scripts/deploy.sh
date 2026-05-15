#!/usr/bin/env bash
# Sawitku — Production deploy script
# Usage: ./scripts/deploy.sh [pull|up|down|restart|logs|status]
#
# Prerequisites:
#   1. cp .env.prod.example .env  (dan isi semua nilai)
#   2. DNS A record → IP server ini
#   3. Port 80 + 443 terbuka di firewall

set -euo pipefail

COMPOSE="docker compose -f docker-compose.yml -f docker-compose.prod.yml"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$PROJECT_DIR"

check_env() {
  local missing=()
  for var in POSTGRES_PASSWORD JWT_SECRET SAWITKU_DOMAIN; do
    [[ -z "${!var:-}" ]] && missing+=("$var")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "ERROR: Variabel berikut wajib diisi di .env:"
    printf '  - %s\n' "${missing[@]}"
    exit 1
  fi
}

# Load .env
if [[ -f .env ]]; then
  set -a; source .env; set +a
else
  echo "ERROR: File .env tidak ditemukan. Jalankan: cp .env.prod.example .env"
  exit 1
fi

case "${1:-up}" in
  pull)
    echo ">>> Pull image terbaru..."
    $COMPOSE pull
    ;;

  build)
    echo ">>> Build backend image..."
    $COMPOSE build --no-cache backend
    ;;

  up)
    check_env
    echo ">>> Deploy Sawitku ke production (domain: ${SAWITKU_DOMAIN})"
    # Backup sebelum deploy
    echo ">>> Backup database sebelum deploy..."
    bash scripts/backup.sh backup || echo "WARN: Backup gagal, lanjut deploy"

    $COMPOSE up -d --build --remove-orphans
    echo ""
    echo ">>> Menunggu backend sehat..."
    timeout 120 bash -c 'until docker inspect sawitku-backend \
      --format "{{.State.Health.Status}}" 2>/dev/null | grep -q healthy; \
      do printf "."; sleep 5; done' && echo " OK"

    echo ""
    echo ">>> Status layanan:"
    $COMPOSE ps
    echo ""
    echo "Sawitku berjalan di https://${SAWITKU_DOMAIN}"
    ;;

  down)
    echo ">>> Menghentikan semua layanan..."
    $COMPOSE down
    ;;

  restart)
    SERVICE="${2:-}"
    if [[ -n "$SERVICE" ]]; then
      echo ">>> Restart $SERVICE..."
      $COMPOSE restart "$SERVICE"
    else
      echo ">>> Restart semua layanan..."
      $COMPOSE restart
    fi
    ;;

  logs)
    SERVICE="${2:-}"
    $COMPOSE logs -f --tail=100 $SERVICE
    ;;

  status)
    $COMPOSE ps
    ;;

  *)
    echo "Usage: $0 [pull|build|up|down|restart [service]|logs [service]|status]"
    exit 1
    ;;
esac
