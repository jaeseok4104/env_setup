#!/usr/bin/env bash
# Configure shell environment: PATH exports and aliases for opencode/bun
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

MARKER_BEGIN="# >>> env_setup managed >>>"
MARKER_END="# <<< env_setup managed <<<"

SHELL_BLOCK='# >>> env_setup managed >>>
# DO NOT EDIT between markers — managed by env_setup scripts

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# <<< env_setup managed <<<'

detect_shell_rc() {
    local shell_name
    shell_name="$(basename "${SHELL:-/bin/bash}")"

    case "$shell_name" in
        bash) echo "$HOME/.bashrc" ;;
        zsh)  echo "$HOME/.zshrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.bashrc" ;;
    esac
}

install_shell_config() {
    local rc_file
    rc_file="$(detect_shell_rc)"

    if [[ ! -f "$rc_file" ]]; then
        log_info "Creating $rc_file..."
        touch "$rc_file"
    fi

    if grep -qF "$MARKER_BEGIN" "$rc_file"; then
        # Replace existing managed block
        log_info "Updating managed block in $rc_file..."
        local tmp_file
        tmp_file="$(mktemp)"

        local in_block=false
        while IFS= read -r line; do
            if [[ "$line" == "$MARKER_BEGIN" ]]; then
                in_block=true
                continue
            fi
            if [[ "$line" == "$MARKER_END" ]]; then
                in_block=false
                continue
            fi
            if [[ "$in_block" == false ]]; then
                echo "$line"
            fi
        done < "$rc_file" > "$tmp_file"

        # Append new block
        echo "" >> "$tmp_file"
        echo "$SHELL_BLOCK" >> "$tmp_file"

        mv "$tmp_file" "$rc_file"
        log_success "Updated managed block in $rc_file"
    else
        # Append new block
        log_info "Adding managed block to $rc_file..."
        echo "" >> "$rc_file"
        echo "$SHELL_BLOCK" >> "$rc_file"
        log_success "Added managed block to $rc_file"
    fi
}

main() {
    log_header "Setting Up Shell Environment"

    install_shell_config

    local rc_file
    rc_file="$(detect_shell_rc)"
    log_info ""
    log_info "To apply changes now, run:"
    log_info "  source $rc_file"

    log_success "Shell environment setup complete"
}

main "$@"
