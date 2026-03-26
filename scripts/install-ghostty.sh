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

set_default_terminal() {
    local ghostty_bin="/snap/bin/ghostty"

    if [[ ! -x "$ghostty_bin" ]]; then
        log_warn "Ghostty binary not found at $ghostty_bin — skipping default terminal setup"
        return 0
    fi

    local current
    current=$(update-alternatives --query x-terminal-emulator 2>/dev/null | grep "^Value:" | awk '{print $2}' || echo "")

    if [[ "$current" == "$ghostty_bin" ]]; then
        log_info "Ghostty is already the default terminal"
        return 0
    fi

    log_info "Registering Ghostty in update-alternatives..."
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$ghostty_bin" 60

    log_info "Setting Ghostty as the default terminal..."
    sudo update-alternatives --set x-terminal-emulator "$ghostty_bin"

    log_success "Ghostty is now the default terminal emulator"
}

main() {
    log_header "Installing Ghostty"

    require_cmd snap

    install_ghostty
    setup_config_dir
    set_default_terminal

    log_success "Ghostty installation complete"
}

main "$@"
