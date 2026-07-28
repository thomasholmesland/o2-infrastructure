#!/usr/bin/env bash

set -Eeuo pipefail

BACKUP_ROOT="/opt/o2/backups/docker"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

PORTAINER_COMPOSE="/opt/o2/o2-infrastructure/compose/infrastructure.yml"
KUMA_COMPOSE="/opt/o2/o2-infrastructure/compose/20-uptime-kuma.yml"

VOLUMES=(
  "portainer_data"
  "monitoring_uptime-kuma"
)

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

restart_services() {
  log "Starter tjenestene igjen."
  docker compose -f "${PORTAINER_COMPOSE}" start || true
  docker compose -f "${KUMA_COMPOSE}" start || true
}

trap restart_services EXIT

mkdir -p "${BACKUP_DIR}"

log "Stopper Portainer og Uptime Kuma."

docker compose -f "${PORTAINER_COMPOSE}" stop
docker compose -f "${KUMA_COMPOSE}" stop

for volume in "${VOLUMES[@]}"; do
  if ! docker volume inspect "${volume}" >/dev/null 2>&1; then
    log "FEIL: Docker-volumet ${volume} finnes ikke."
    exit 1
  fi

  log "Sikkerhetskopierer ${volume}."

  docker run --rm \
    --volume "${volume}:/source:ro" \
    --volume "${BACKUP_DIR}:/backup" \
    alpine:3.22 \
    tar -czf "/backup/${volume}.tar.gz" -C /source .
done

docker version > "${BACKUP_DIR}/docker-version.txt"
docker compose version > "${BACKUP_DIR}/compose-version.txt"
docker volume ls > "${BACKUP_DIR}/docker-volumes.txt"
docker ps -a > "${BACKUP_DIR}/docker-containers.txt"

sha256sum "${BACKUP_DIR}"/*.tar.gz > "${BACKUP_DIR}/SHA256SUMS"

find "${BACKUP_ROOT}" \
  -mindepth 1 \
  -maxdepth 1 \
  -type d \
  -mtime +14 \
  -exec rm -rf {} +

log "Backup fullført: ${BACKUP_DIR}"
