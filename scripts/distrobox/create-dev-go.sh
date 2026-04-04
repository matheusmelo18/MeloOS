#!/usr/bin/env bash
set -euo pipefail

cfg_dir="$(dirname "$0")/../../distrobox"
distrobox create --file "${cfg_dir}/dev-go.conf" "$@"
