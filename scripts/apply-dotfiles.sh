#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/meloos-install"
BACKUP_DIR="${STATE_DIR}/dotfiles-backup"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dotfiles/hyprluna/home"

log(){ printf '%s\n' "$*"; }
backup_path(){ local rel="$1"; local dst="${BACKUP_DIR}/${rel}"
  mkdir -p "$(dirname "${dst}")"
  if [[ -e "$HOME/${rel}" || -L "$HOME/${rel}" ]]; then
    mv "$HOME/${rel}" "${dst}.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

apply_item(){ local rel="$1"; local src="${SRC_DIR}/${rel}"; local dst="$HOME/${rel}"
  mkdir -p "$(dirname "${dst}")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ -d "$dst" && ! -L "$dst" && -d "$src" ]]; then
      return 0
    fi
    cmp -s "$src" "$dst" 2>/dev/null && return 0
    backup_path "$rel"
  fi
  cp -a "$src" "$dst"
}

main(){
  mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"
  local rel
  shopt -s globstar nullglob
  for rel in "${SRC_DIR}"/**; do
    [[ -f "$rel" ]] || continue
    rel="${rel#${SRC_DIR}/}"
    apply_item "$rel"
  done
  log "HyprLuna-inspired dotfiles applied."
}

main "$@"
