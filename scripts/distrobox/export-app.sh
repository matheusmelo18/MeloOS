#!/usr/bin/env bash
set -euo pipefail

container="${1:?container name required}"
app="${2:?app name required}"

distrobox enter "$container" -- distrobox-export --app "$app"
