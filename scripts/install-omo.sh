#!/usr/bin/env bash
# Deploy OMO (Oh-My-OpenCode) configs and install as opencode plugin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/_common.sh"

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"

CONFIG_FILES=(
    "opencode.json"
    "oh-my-opencode.json"
    "oh-my-opencode-copilot.json"
    "oh-my-opencode.full.json"
    "oh-my-opencode.spark.json"
)

deploy_configs() {
    local force="${1:-false}"

    mkdir -p "$OPENCODE_CONFIG_DIR"

    for config_file in "${CONFIG_FILES[@]}"; do
        local src="${REPO_DIR}/configs/${config_file}"
        local dest="${OPENCODE_CONFIG_DIR}/${config_file}"

        if [[ ! -f "$src" ]]; then
            log_error "Config file not found: $src"
            exit 1
        fi

        if [[ -f "$dest" ]] && [[ "$force" != "true" ]]; then
            log_info "Config already exists (skipping): $config_file"
            log_info "  Use --force to overwrite"
        else
            cp "$src" "$dest"
            log_success "Deployed: $config_file"
        fi
    done
}

setup_config_gitignore() {
    local gitignore="$OPENCODE_CONFIG_DIR/.gitignore"
    if [[ ! -f "$gitignore" ]]; then
        log_info "Creating .gitignore in opencode config dir..."
        cat > "$gitignore" <<'EOF'
node_modules
package.json
bun.lock
.gitignore
antigravity-accounts.json
antigravity-signature-cache.json
antigravity-logs/
EOF
        log_success "Created .gitignore"
    fi
}

install_plugins() {
    # Create package.json for plugin resolution
    local pkg_file="$OPENCODE_CONFIG_DIR/package.json"
    if [[ ! -f "$pkg_file" ]]; then
        log_info "Creating package.json for plugin resolution..."
        cat > "$pkg_file" <<'EOF'
{
  "dependencies": {
    "@opencode-ai/plugin": "1.3.2"
  }
}
EOF
    fi

    # Install plugin dependencies (opencode resolves plugins on first run,
    # but we pre-install to ensure everything is ready)
    log_info "Installing opencode plugins via bun..."
    (cd "$OPENCODE_CONFIG_DIR" && bun install --no-progress)
    log_success "Plugins installed"
}

print_auth_reminder() {
    log_warn "========================================="
    log_warn "  MANUAL SETUP REQUIRED"
    log_warn "========================================="
    log_warn ""
    log_warn "The following must be configured manually:"
    log_warn ""
    log_warn "1. GitHub Copilot authentication:"
    log_warn "   Run 'opencode' and sign in via GitHub"
    log_warn ""
    log_warn "2. Google Antigravity auth (optional):"
    log_warn "   Configure antigravity-accounts.json"
    log_warn "   in ~/.config/opencode/"
    log_warn ""
    log_warn "3. OpenAI API key (optional):"
    log_warn "   Run 'opencode' and configure OpenAI provider"
    log_warn ""
    log_warn "========================================="
}

main() {
    log_header "Installing OMO (Oh-My-OpenCode)"

    local force="false"
    for arg in "$@"; do
        case "$arg" in
            --force|-f) force="true" ;;
        esac
    done

    require_cmd bun

    deploy_configs "$force"
    setup_config_gitignore
    install_plugins
    print_auth_reminder

    log_success "OMO installation complete"
}

main "$@"
