# MeloOS

MeloOS is an immutable Linux system based on Fedora bootc with Hyprland as the graphical interface.
The host image currently targets Fedora 43.
It is designed to be ready to use after installation, with:

- a desktop host built from the image (Hyprland)
- development tools isolated in Distrobox
- desktop apps installed through Flatpak

For a complete end-to-end walkthrough, see [docs/tutorial.md](docs/tutorial.md).
For the dotfiles profile used by the desktop, see [docs/dotfiles.md](docs/dotfiles.md).

## What this system is

MeloOS is not a traditional distro where you install everything on the host.
The idea is:

- **Host**: only system-level packages and desktop integration
- **Distrobox**: Java, Node and other dev toolchains
- **Flatpak**: desktop apps
- **Dotfiles**: a HyprLuna-inspired profile applied after install

This keeps the host clean, reproducible and easy to rebuild.

## Main stack

- **Host base**: Fedora bootc + Hyprland
- **Hyprland stack**: fornecida via COPR no Fedora 43
- **Java container**: Ubuntu 24.04 + SDKMAN
- **Node container**: Arch Linux
- **Desktop apps**: Flatpak
- **Desktop profile**: original HyprLuna-inspired configs for Hyprland, Waybar, Kitty, Wofi, Dunst, Hyprpaper, Hyprlock, Hypridle and a lightweight AGS placeholder

## Included apps

The bootstrap installs these Flatpaks:

- Discord
- ZapZap
- LocalSend
- Bazaar
- GitKraken
- Spotify
- DistroShelf
- Flatseal
- Podman Desktop
- Warehouse
- Postman
- Trayscale

## How it works

### Host layer

The host image contains the desktop and system services needed to boot and use MeloOS.
The host is immutable, so changes must be made in the image build files, not by random package installs on the running system.

### Distrobox layer

Development tools are separated into containers:

- `dev-java` for Java and SDKMAN
- `dev-node` for Node.js

This gives you different Linux bases for different stacks without polluting the host.

### Flatpak layer

Apps like Discord, Spotify and LocalSend are installed on the host through Flatpak.
This keeps them isolated and easy to update.

## Step-by-step install

### 1. Install the MeloOS image

Install the generated bootc/ISO image on your machine or VM.

### 2. Boot the system

After first boot, log in to the desktop normally.

### 3. Run the installer

Open a terminal and run:

```bash
just install
```

### 4. Reboot if asked

If the host needs extra base packages on `rpm-ostree`, the script queues them and creates a small user-level resume service. After reboot and login, the installer runs again and skips completed steps.

### 5. Use the dev containers

Enter the Java container:

```bash
distrobox enter dev-java
```

Enter the Node container:

```bash
distrobox enter dev-node
```

### 6. Dotfiles profile

MeloOS now applies a HyprLuna-inspired dotfiles profile from `dotfiles/hyprluna/home`.
It is an original Fedora 43-friendly setup, not a copy of the archived HyprLuna project.

To customize it, edit the files in that tree and rerun:

```bash
just install
```

The apply script is idempotent and backs up conflicting files into `~/.local/state/meloos-install/dotfiles-backup`.

## Main installer flow

`just install` is the preferred command.

It performs these steps:

1. check host tools
2. install missing host packages with `rpm-ostree` when required
3. resume automatically after reboot if the host layer changed
4. add Flathub
5. install all desktop Flatpaks
6. create `dev-java` and `dev-node`
7. initialize SDKMAN in `dev-java`
8. verify the Node container is healthy
9. apply the dotfiles profile into the user home directory

## Switching to a custom image

If you want to use your own MeloOS-based image, keep `just install` as the only post-install path and change only the host image source.

### 1. Build your image

Build from this repository:

```bash
just build your-user/meloos custom
```

Publish it to your own registry or GHCR, for example `ghcr.io/you/meloos:custom`.

Recommended tags:

- `latest` for daily use
- `stable` for machines you do not want to change often
- a version tag or digest for rollback-safe pinning

### 2. Generate bootable artifacts

Use the existing bootc image builder targets:

```bash
just build-qcow2 ghcr.io/you/meloos custom
just build-raw ghcr.io/you/meloos custom
just build-iso ghcr.io/you/meloos custom
```

These produce the VM and installer artifacts under `output/`.

- **QCOW2**: best for virtual machines
- **RAW**: best for disk flashing or low-level image use
- **ISO**: best for fresh installation on physical hardware or VMs

### 3. Switch an installed system to your image

On a running MeloOS host, point bootc at the new image:

```bash
sudo bootc switch ghcr.io/you/meloos:custom
```

After the reboot, the machine will track your GHCR image instead of the default one.

If you want the safest workflow, pin a digest instead of a moving tag:

```bash
sudo bootc switch ghcr.io/you/meloos@sha256:...
```

Rollback is handled by bootc/ostree, so if the new deployment is wrong you can boot the previous one.

### 4. Reboot and validate

Reboot the machine and confirm the new deployment is active:

```bash
systemctl reboot
bootc status
```

Validate the expected setup:

- Hyprland starts on the host
- Distrobox containers provide Java and Node
- Flatpak apps are installed and working

### 5. Roll back if needed

If the new image has a problem, roll back to the previous deployment:

```bash
sudo bootc rollback
systemctl reboot
```

After reboot, confirm the system returned to the prior known-good image.

## What the bootstrap does

The installer is idempotent and non-interactive.
It:

- checks host dependencies
- installs missing host dependencies with `rpm-ostree` when needed
- records named steps in `~/.local/state/meloos-install/state.env`
- resumes automatically after `rpm-ostree` reboots when possible
- adds Flathub if needed
- installs the desktop Flatpaks
- creates the Java and Node containers
- initializes SDKMAN in the Java container
- uses the Node Distrobox profile for `nodejs`/`npm` and does not bootstrap them manually

## Exact host role

The host image is responsible for:

- Hyprland and its Wayland session stack
- Tailscale on the host
- Podman and Distrobox integration
- Flatpak support for desktop apps
- only system-level packages

Toolchains stay out of the host image.

## Java setup

The Java container uses Ubuntu 24.04 and SDKMAN.
Inside it, you can manage JDKs, Maven and Gradle without installing them on the host.

## Node setup

The Node container uses Arch Linux.
Its Distrobox profile already installs `nodejs`, `npm` and the helper tooling, so the installer only verifies the container is healthy.

## Daily use

- Use the host for desktop apps and system tasks
- Use `dev-java` for Java projects
- Use `dev-node` for Node projects
- Export GUI apps from containers only when needed

## Useful commands

Create or refresh the Java container:

```bash
just create-dev-java
```

Create or refresh the Node container:

```bash
just create-dev-node
```

Export a GUI app from a container:

```bash
just export-dev-app <container> <app>
```

## Repository layout

- `Containerfile`: host image definition
- `build_files/build.sh`: host package and service setup
- `distrobox/`: Distrobox profiles
- `scripts/distrobox/`: helper scripts for containers
- `scripts/install.sh`: main post-install installer
- `Justfile`: helper commands

## Tailscale

Tailscale is installed in the host image so it fits the immutable bootc model.
Its service is enabled from `build_files/build.sh`, which is the preferred place for host-level networking services.

Trayscale is provided as a Flatpak GUI on top of that host service.

## Maintenance

- Update the image from the repo when host changes are needed
- Update Distrobox profiles when a stack changes
- Update Flatpak IDs in `scripts/install.sh` if upstream names change

## Troubleshooting

### Install fails

- Check that `podman`, `distrobox`, `flatpak`, and `just` are available
- If the script queued host package installs, reboot and log in again
- The installer resumes automatically on login when `rpm-ostree` was involved
- You can always rerun `just install`; completed steps are skipped from the state file

### Container creation fails

- Check Distrobox and Podman status
- Remove the broken container and run the bootstrap again

### Flatpak app missing

- Verify Flathub is enabled
- Check whether the app ID changed upstream

## Philosophy

MeloOS aims to be:

- reproducible
- clean
- easy to reinstall
- ready to use after setup
- flexible for development without sacrificing host integrity
