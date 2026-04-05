#!/usr/bin/env bash
set -euo pipefail

fail=0

check() {
  local pattern="$1" file="$2" message="$3"
  if grep -Eq "$pattern" "$file"; then
    printf 'gate failed: %s\n' "$message" >&2
    fail=1
  fi
}

check 'rpm-ostree[[:space:]]+install' 'scripts/install.sh' 'rpm-ostree install reintroduced in scripts/install.sh'
check 'curl[[:space:]]*\|[[:space:]]*bash|sdkman' 'scripts/install.sh' 'SDKMAN bootstrap or curl | bash reintroduced in scripts/install.sh'
check 'archlinux:latest' 'distrobox/dev-node.conf' 'archlinux:latest reintroduced in distrobox/dev-node.conf'
check 'osbuild/bootc-image-builder-action@main' '.github/workflows/build-disk.yml' 'bootc-image-builder-action@main reintroduced in workflows'

exit "$fail"
