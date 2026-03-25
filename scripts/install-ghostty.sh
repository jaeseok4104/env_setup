#!/usr/bin/env bash
# Install Ghostty terminal emulator via snap
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

install_ghostty() {
    if command -v ghostty &>/dev/null; then
        local version
        version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
        log_info "Ghostty is already installed: $version"
        return 0
    fi

    # Also check snap directly
    if snap list ghostty &>/dev/null 2>&1; then
        log_info "Ghostty is already installed via snap"
        return 0
    fi

    log_info "Installing Ghostty via snap..."
    sudo snap install ghostty --classic
    log_success "Ghostty installed: $(ghostty --version 2>/dev/null | head -1)"
}

setup_config_dir() {
    # Create config directory for future customization
    local config_dir="$HOME/.config/ghostty"
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
        log_info "Created config directory: $config_dir"
        log_info "  (No custom config — running on defaults)"
    fi
}

main() {
    log_header "Installing Ghostty"

    require_cmd snap

    install_ghostty
    setup_config_dir

    log_success "Ghostty installation complete"
}

main "$@"
