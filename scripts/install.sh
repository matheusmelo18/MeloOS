#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/meloos-install"
STATE_FILE="${STATE_DIR}/state.env"
LOCK_FILE="${STATE_DIR}/lock"
RESUME_UNIT_DIR="${HOME}/.config/systemd/user"
RESUME_UNIT="${RESUME_UNIT_DIR}/meloos-install-resume.service"
RESUME_MARKER="resume-pending"

HOST_PACKAGES=(podman distrobox flatpak just)
FLATPAK_REMOTE_NAME="flathub"
FLATPAK_REMOTE_URL="https://flathub.org/repo/flathub.flatpakrepo"
FLATPAK_APPS=(
  "com.discordapp.Discord"
  "com.rtosta.zapzap"
  "org.localsend.localsend_app"
  "io.github.kolunmi.Bazaar"
  "com.axosoft.GitKraken"
  "com.spotify.Client"
  "com.ranfdev.DistroShelf"
  "com.github.tchx84.Flatseal"
  "io.podman_desktop.PodmanDesktop"
  "io.github.flattool.Warehouse"
  "com.getpostman.Postman"
  "io.github.marhkb.Pods"
  "dev.deedles.Trayscale"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

mkdir -p "${STATE_DIR}"
exec 9>"${LOCK_FILE}"
flock -n 9 || exit 0

log(){ printf '%s\n' "$*"; }
have_cmd(){ command -v "$1" >/dev/null 2>&1; }
state_value(){ grep -E "^${1}=" "${STATE_FILE}" 2>/dev/null | tail -n1 | cut -d= -f2-; }
is_done(){ [[ "$(state_value "$1")" == "done" ]]; }
set_state(){ mkdir -p "${STATE_DIR}"; touch "${STATE_FILE}"; if grep -q "^${1}=" "${STATE_FILE}" 2>/dev/null; then sed -i "s/^${1}=.*/${1}=${2}/" "${STATE_FILE}"; else printf '%s=%s\n' "$1" "$2" >>"${STATE_FILE}"; fi; }
mark_done(){ set_state "$1" done; }
run_step(){ local name="$1"; shift; is_done "$name" && { log "Skipping ${name} (done)."; return 0; }; log "Running ${name}..."; "$@"; mark_done "$name"; }

install_resume_service(){
  mkdir -p "${RESUME_UNIT_DIR}"
  cat >"${RESUME_UNIT}" <<EOF
[Unit]
Description=MeloOS installer resume

[Service]
Type=oneshot
ExecStart=${SCRIPT_DIR}/install.sh

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  systemctl --user enable --now meloos-install-resume.service >/dev/null 2>&1 || true
  set_state resume "${RESUME_MARKER}"
}

ensure_host_packages(){
  local missing=() pkg
  for pkg in "${HOST_PACKAGES[@]}"; do have_cmd "$pkg" || missing+=("$pkg"); done
  (( ${#missing[@]} == 0 )) && return 0
  log "Missing host dependencies: ${missing[*]}"
  log "Rebuild the host image or install these prerequisites outside the install flow, then rerun scripts/install.sh."
  exit 1
}

ensure_flathub(){
  flatpak remote-list --columns=name | grep -qx "${FLATPAK_REMOTE_NAME}" || flatpak remote-add --if-not-exists --system "${FLATPAK_REMOTE_NAME}" "${FLATPAK_REMOTE_URL}"
}

install_flatpaks(){
  ensure_flathub
  for app in "${FLATPAK_APPS[@]}"; do flatpak install -y --system "${FLATPAK_REMOTE_NAME}" "$app"; done
  mark_done flatpaks
}

ensure_container(){
  local recipe="$1" name="$2"
  distrobox list --no-color 2>/dev/null | grep -qE "^[[:space:]]*${name}[[:space:]]" || bash "${ROOT_DIR}/${recipe}"
}

setup_java_container(){
  distrobox enter dev-java -- bash -lc '
    set -euo pipefail
    command -v java >/dev/null 2>&1 || { echo "dev-java is not ready: java is missing from the container image. Rebuild the container first." >&2; exit 1; }
    command -v mvn >/dev/null 2>&1 || { echo "dev-java is not ready: maven is missing from the container image. Rebuild the container first." >&2; exit 1; }
    command -v gradle >/dev/null 2>&1 || { echo "dev-java is not ready: gradle is missing from the container image. Rebuild the container first." >&2; exit 1; }
  '
}

setup_node_container(){
  distrobox enter dev-node -- bash -lc '
    set -euo pipefail
    command -v node >/dev/null 2>&1 || { echo "nodejs is missing from the dev-node profile" >&2; exit 1; }
  '
}

main(){
  run_step host-packages ensure_host_packages
  run_step flatpaks install_flatpaks
  run_step containers ensure_containers
  run_step java-toolchain setup_java_container
  run_step node-toolchain setup_node_container
  run_step dotfiles bash "${ROOT_DIR}/scripts/apply-dotfiles.sh"
  log "MeloOS install complete."
}

ensure_containers(){
  ensure_container scripts/distrobox/create-dev-java.sh dev-java
  ensure_container scripts/distrobox/create-dev-node.sh dev-node
}

main "$@"
