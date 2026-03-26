#!/usr/bin/env bash
# Install Docker CE, Docker Compose plugin, and configure NVIDIA runtime
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

DOCKER_PACKAGES=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
DOCKER_SOURCES="/etc/apt/sources.list.d/docker.sources"

check_docker_installed() {
    if command -v docker &>/dev/null; then
        local version
        version=$(docker --version 2>/dev/null || echo "unknown")
        log_info "Docker is already installed: $version"
        return 0
    fi
    return 1
}

setup_docker_apt_repo() {
    # Install prerequisites for apt over HTTPS
    local prereqs=(ca-certificates curl)
    local missing=()

    for pkg in "${prereqs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Installing APT prerequisites: ${missing[*]}"
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${missing[@]}"
    fi

    # Add Docker's official GPG key
    if [[ ! -f "$DOCKER_KEYRING" ]]; then
        log_info "Adding Docker GPG key..."
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL "$DOCKER_GPG_URL" -o "$DOCKER_KEYRING"
        sudo chmod a+r "$DOCKER_KEYRING"
        log_success "Docker GPG key added: $DOCKER_KEYRING"
    else
        log_info "Docker GPG key already exists: $DOCKER_KEYRING"
    fi

    # Add Docker APT repository (DEB822 format for Ubuntu 24.04+)
    if [[ ! -f "$DOCKER_SOURCES" ]]; then
        log_info "Adding Docker APT repository..."
        local codename
        codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
        sudo tee "$DOCKER_SOURCES" > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${codename}
Components: stable
Signed-By: ${DOCKER_KEYRING}
EOF
        log_success "Docker APT source added: $DOCKER_SOURCES"
        sudo apt-get update -qq
    else
        log_info "Docker APT source already exists: $DOCKER_SOURCES"
    fi
}

install_docker_packages() {
    local to_install=()

    for pkg in "${DOCKER_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing Docker packages: ${to_install[*]}"
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${to_install[@]}"
        log_success "Docker packages installed"
    else
        log_info "All Docker packages already installed"
    fi
}

setup_docker_group() {
    local user
    user=$(whoami)

    if id -nG "$user" | grep -qw docker; then
        log_info "User '$user' is already in the docker group"
        return 0
    fi

    log_info "Adding user '$user' to docker group..."
    sudo usermod -aG docker "$user"
    log_success "User '$user' added to docker group"
    log_warn "You may need to log out and back in for group changes to take effect"
}

enable_docker_service() {
    if systemctl is-enabled --quiet docker 2>/dev/null; then
        log_info "Docker service is already enabled"
    else
        log_info "Enabling Docker service..."
        sudo systemctl enable docker
        log_success "Docker service enabled"
    fi

    if systemctl is-active --quiet docker; then
        log_info "Docker service is running"
    else
        log_info "Starting Docker service..."
        sudo systemctl start docker
        log_success "Docker service started"
    fi
}

verify_installation() {
    log_info "Verifying Docker installation..."

    if ! command -v docker &>/dev/null; then
        log_error "docker command not found after installation"
        return 1
    fi

    local docker_version
    docker_version=$(docker --version)
    log_success "Docker: $docker_version"

    if docker compose version &>/dev/null; then
        local compose_version
        compose_version=$(docker compose version)
        log_success "Docker Compose: $compose_version"
    else
        log_warn "Docker Compose plugin not available"
    fi
}

main() {
    log_header "Installing Docker"

    setup_docker_apt_repo
    install_docker_packages
    setup_docker_group
    enable_docker_service
    verify_installation

    log_success "Docker installation complete"
}

main "$@"
