#!/usr/bin/env bash
# Install required dependencies: bun, node, snap prerequisites
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

MIN_NODE_VERSION=22
BUN_INSTALL_URL="https://bun.sh/install"

install_system_packages() {
    local packages=()

    for cmd in curl unzip jq; do
        if ! command -v "$cmd" &>/dev/null; then
            packages+=("$cmd")
        fi
    done

    if [[ ${#packages[@]} -gt 0 ]]; then
        log_info "Installing system packages: ${packages[*]}"
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${packages[@]}"
    else
        log_info "All system packages already installed (curl, unzip, jq)"
    fi
}

install_snap() {
    if command -v snap &>/dev/null; then
        log_info "snap is already installed: $(snap --version | head -1)"
        return 0
    fi

    log_info "Installing snapd..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq snapd
    log_success "snapd installed"
}

install_node() {
    if command -v node &>/dev/null; then
        local current_version
        current_version=$(node --version | sed 's/v//' | cut -d. -f1)
        if [[ "$current_version" -ge "$MIN_NODE_VERSION" ]]; then
            log_info "Node.js already installed: $(node --version)"
            return 0
        fi
        log_warn "Node.js $(node --version) is too old (need >= v${MIN_NODE_VERSION})"
    fi

    log_info "Installing Node.js v${MIN_NODE_VERSION}..."
    curl -fsSL "https://deb.nodesource.com/setup_${MIN_NODE_VERSION}.x" | sudo -E bash -
    sudo apt-get install -y -qq nodejs
    log_success "Node.js installed: $(node --version)"
}

install_bun() {
    if command -v bun &>/dev/null; then
        log_info "bun is already installed: $(bun --version)"
        return 0
    fi

    if [[ -x "$HOME/.bun/bin/bun" ]]; then
        log_info "bun found at ~/.bun/bin/bun: $("$HOME/.bun/bin/bun" --version)"
        return 0
    fi

    log_info "Installing bun..."
    curl -fsSL "$BUN_INSTALL_URL" | bash
    log_success "bun installed: $("$HOME/.bun/bin/bun" --version)"
}

main() {
    log_header "Installing Dependencies"

    install_system_packages
    install_snap
    install_node
    install_bun

    log_success "All dependencies installed"
}

main "$@"
