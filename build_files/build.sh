#!/usr/bin/bash

set -ouex pipefail

# MeloOS host customization script
# Target: immutable host image (bootc/rpm-ostree)
# Note: development toolchains (Java, Node, Go, etc.) belong in Distrobox containers.

# Keep this script idempotent and deterministic.
# All host-level package changes should be made here.

# -------------------------------------------------------------------
# External repositories
# -------------------------------------------------------------------

# Fedora 43 does not ship the full Hyprland stack in the default repos.
# Enable the COPR used by this image before installing host packages.
cat >/etc/yum.repos.d/copr-solopasha-hyprland.repo <<'EOF'
[copr:copr.fedorainfracloud.org:solopasha:hyprland]
name=Copr repo for hyprland owned by solopasha
baseurl=https://download.copr.fedorainfracloud.org/results/solopasha/hyprland/fedora-$releasever-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/solopasha/hyprland/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

# -------------------------------------------------------------------
# Package groups
# -------------------------------------------------------------------

BASE_PACKAGES=(
    # Core utilities
    curl
    wget
    git
    tmux
    vim-enhanced
    htop
    fastfetch
    tree
    unzip
    zip
    rsync
    jq

    # Networking / diagnostics
    NetworkManager-tui
    bind-utils
    traceroute
    iperf3

    # Containers / virtualization workflow
    podman
    podman-compose
    distrobox
    flatpak
    tailscale
    desktop-file-utils
    shared-mime-info

    # Audio stack
    pipewire
    wireplumber
    pavucontrol
    playerctl

    # Wayland / desktop essentials for Hyprland sessions
    hyprland
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    waybar
    wofi
    dunst
    hypridle
    hyprlock
    hyprpaper
    kitty

    # Session and auth integration
    polkit
    lxqt-policykit
    dbus-daemon

    # Display / seat management
    seatd
    wl-clipboard
    grim
    slurp

    # Filesystem / desktop integration
    gvfs
    gvfs-mtp

    # Fonts
    google-noto-sans-fonts
    google-noto-emoji-fonts
    fontconfig
)

# -------------------------------------------------------------------
# Install host packages (immutable image layer)
# -------------------------------------------------------------------

rpm-ostree install "${BASE_PACKAGES[@]}"

# -------------------------------------------------------------------
# Enable system services needed on host
# -------------------------------------------------------------------

systemctl enable podman.socket
systemctl enable seatd.service
systemctl enable tailscaled.service

# -------------------------------------------------------------------
# Optional host defaults
# -------------------------------------------------------------------

# Ensure default target is graphical for desktop usage.
systemctl set-default graphical.target

# If this image is used on laptops, you can later add:
# rpm-ostree install power-profiles-daemon
# systemctl enable power-profiles-daemon.service

# -------------------------------------------------------------------
# Cleanup
# -------------------------------------------------------------------

# Keep image metadata clean after package operations.
rpm-ostree cleanup -m
