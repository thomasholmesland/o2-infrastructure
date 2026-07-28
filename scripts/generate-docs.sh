#!/usr/bin/env bash

set -Eeuo pipefail

REPO_ROOT="/opt/o2/o2-infrastructure"
OUTPUT_DIR="${REPO_ROOT}/docs/generated"
GENERATED_AT="$(date --iso-8601=seconds)"
HOSTNAME_VALUE="$(hostname)"
HOST_IP="$(hostname -I | awk '{print $1}')"

mkdir -p "${OUTPUT_DIR}"

generate_header() {
  local title="$1"

  cat <<EOF
# ${title}

> Automatisk generert fra \`${HOSTNAME_VALUE}\`  
> Generert: \`${GENERATED_AT}\`  
> Server-IP: \`${HOST_IP}\`

Denne filen skal ikke redigeres manuelt.

EOF
}

generate_services() {
  local file="${OUTPUT_DIR}/services.md"

  {
    generate_header "Docker-tjenester"

    echo "| Container | Image | Status | Restart policy |"
    echo "|---|---|---|---|"

    docker ps -a \
      --format '{{.Names}}|{{.Image}}|{{.Status}}' |
      sort |
      while IFS='|' read -r name image status; do
        restart_policy="$(
          docker inspect \
            --format '{{.HostConfig.RestartPolicy.Name}}' \
            "${name}"
        )"

        printf '| `%s` | `%s` | %s | `%s` |\n' \
          "${name}" \
          "${image}" \
          "${status}" \
          "${restart_policy:-none}"
      done
  } > "${file}"
}

generate_ports() {
  local file="${OUTPUT_DIR}/ports.md"

  {
    generate_header "Publiserte porter"

    echo "| Container | Vert-IP | Vert-port | Containerport | Protokoll |"
    echo "|---|---|---:|---:|---|"

    docker ps -a --format '{{.Names}}' |
      sort |
      while read -r container; do

        docker inspect \
          --format '{{range $port, $bindings := .NetworkSettings.Ports}}{{if $bindings}}{{range $bindings}}{{$.Name}}|{{.HostIp}}|{{.HostPort}}|{{$port}}{{println}}{{end}}{{end}}{{end}}' \
          "${container}"
      done |
      while IFS='|' read -r name host_ip host_port container_port; do
        [ -z "${name}" ] && continue

        port_number="${container_port%/*}"
        protocol="${container_port#*/}"

        printf '| `%s` | `%s` | `%s` | `%s` | `%s` |\n' \
          "${name}" \
          "${host_ip:-0.0.0.0}" \
          "${host_port}" \
          "${port_number}" \
          "${protocol}"
      done
  } > "${file}"
}

generate_networks() {
  local file="${OUTPUT_DIR}/networks.md"

  {
    generate_header "Docker-nettverk"

    for network in $(docker network ls --format '{{.Name}}' | sort); do
      driver="$(docker network inspect \
        --format '{{.Driver}}' "${network}")"

      scope="$(docker network inspect \
        --format '{{.Scope}}' "${network}")"

      echo "## \`${network}\`"
      echo
      echo "- Driver: \`${driver}\`"
      echo "- Scope: \`${scope}\`"
      echo
      echo "| Container | IPv4-adresse |"
      echo "|---|---|"

      docker network inspect \
        --format '{{range $id, $container := .Containers}}{{$container.Name}}|{{$container.IPv4Address}}{{println}}{{end}}' \
        "${network}" |
        sort |
        while IFS='|' read -r name ip; do
          [ -z "${name}" ] && continue
          printf '| `%s` | `%s` |\n' "${name}" "${ip}"
        done

      echo
    done
  } > "${file}"
}

generate_volumes() {
  local file="${OUTPUT_DIR}/volumes.md"

  {
    generate_header "Docker-volumer"

    echo "| Volum | Driver | Brukt av |"
    echo "|---|---|---|"

    docker volume ls --format '{{.Name}}|{{.Driver}}' |
      sort |
      while IFS='|' read -r volume driver; do

        containers="$(
          docker ps -a --format '{{.Names}}' |
            while read -r container; do
              docker inspect \
                --format '{{range .Mounts}}{{if eq .Type "volume"}}{{if eq .Name "'"${volume}"'"}}{{$.Name}}{{println}}{{end}}{{end}}{{end}}' \
                "${container}"
            done |
            sort -u |
            paste -sd ', ' -
        )"

        printf '| `%s` | `%s` | %s |\n' \
          "${volume}" \
          "${driver}" \
          "${containers:-Ikke tilkoblet}"
      done
  } > "${file}"
}

generate_compose_files() {
  local file="${OUTPUT_DIR}/compose-files.md"

  {
    generate_header "Compose-filer"

    echo "| Fil | Validering | Tjenester |"
    echo "|---|---|---|"

    find "${REPO_ROOT}/compose" \
      -maxdepth 1 \
      -type f \
      \( -name '*.yml' -o -name '*.yaml' \) |
      sort |
      while read -r compose_file; do

        filename="$(basename "${compose_file}")"

        if validation_output="$(
          docker compose -f "${compose_file}" config --services 2>/dev/null
        )"; then
          validation="OK"
          services="$(
            printf '%s\n' "${validation_output}" |
              paste -sd ', ' -
          )"
        else
          validation="FEIL"
          services="Kunne ikke leses"
        fi

        printf '| `%s` | %s | %s |\n' \
          "${filename}" \
          "${validation}" \
          "${services:-Ingen}"
      done
  } > "${file}"
}

generate_timers() {
  local file="${OUTPUT_DIR}/systemd-timers.md"

  {
    generate_header "Systemd-timere"

    echo '```text'
    systemctl list-timers --all --no-pager
    echo '```'
  } > "${file}"
}

generate_backups() {
  local file="${OUTPUT_DIR}/backups.md"
  local backup_root="/opt/o2/backups/docker"

  {
    generate_header "Docker-backuper"

    echo "| Backup | Størrelse | Opprettet |"
    echo "|---|---:|---|"

    if [ -d "${backup_root}" ]; then
      find "${backup_root}" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf '%f\n' |
        sort -r |
        while read -r backup; do

          size="$(du -sh "${backup_root}/${backup}" | awk '{print $1}')"
          created="$(
            stat -c '%y' "${backup_root}/${backup}" |
              cut -d'.' -f1
          )"

          printf '| `%s` | `%s` | `%s` |\n' \
            "${backup}" \
            "${size}" \
            "${created}"
        done
    else
      echo '| Ingen backuper funnet | – | – |'
    fi
  } > "${file}"
}

generate_summary() {
  local file="${OUTPUT_DIR}/README.md"

  container_count="$(docker ps -a -q | wc -l)"
  running_count="$(docker ps -q | wc -l)"
  volume_count="$(docker volume ls -q | wc -l)"
  network_count="$(docker network ls -q | wc -l)"

  {
    generate_header "O2 Infrastructure – generert oversikt"

    echo "## Sammendrag"
    echo
    echo "| Ressurs | Antall |"
    echo "|---|---:|"
    echo "| Containere totalt | ${container_count} |"
    echo "| Containere som kjører | ${running_count} |"
    echo "| Docker-volumer | ${volume_count} |"
    echo "| Docker-nettverk | ${network_count} |"
    echo

    echo "## Dokumenter"
    echo
    echo "- [Docker-tjenester](services.md)"
    echo "- [Publiserte porter](ports.md)"
    echo "- [Docker-nettverk](networks.md)"
    echo "- [Docker-volumer](volumes.md)"
    echo "- [Compose-filer](compose-files.md)"
    echo "- [Systemd-timere](systemd-timers.md)"
    echo "- [Docker-backuper](backups.md)"
  } > "${file}"
}

generate_services
generate_ports
generate_networks
generate_volumes
generate_compose_files
generate_timers
generate_backups
generate_summary

echo "Dokumentasjon generert i:"
echo "${OUTPUT_DIR}"
