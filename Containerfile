# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/fedora/fedora-bootc:43

## Other possible base images include:
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image (newer tag example): quay.io/fedora/fedora-bootc:43
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages (e.g. google-chrome, docker-desktop).
##
## Uncomment the following line if you want /opt to be immutable and managed in the image.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## Make desired image customizations and install packages by editing build.sh.
## The following RUN directive executes build.sh in a recommended bootc-compatible way.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
