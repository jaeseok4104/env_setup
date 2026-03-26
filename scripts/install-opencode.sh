#!/usr/bin/env bash
# Install opencode binary from GitHub releases
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

OPENCODE_REPO="anomalyco/opencode"
OPENCODE_DIR="$HOME/.opencode"
OPENCODE_BIN_DIR="$OPENCODE_DIR/bin"
OPENCODE_BIN="$OPENCODE_BIN_DIR/opencode"

detect_platform() {
    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    case "$os" in
        linux) os="linux" ;;
        darwin) os="darwin" ;;
        *) log_error "Unsupported OS: $os"; exit 1 ;;
    esac

    case "$arch" in
        x86_64|amd64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) log_error "Unsupported architecture: $arch"; exit 1 ;;
    esac

    echo "${os}-${arch}"
}

get_latest_version() {
    local version
    version=$(curl -fsSL "https://api.github.com/repos/${OPENCODE_REPO}/releases/latest" \
        | jq -r '.tag_name' \
        | sed 's/^v//')
    echo "$version"
}

install_opencode() {
    local version="${OPENCODE_VERSION:-}"
    local platform
    platform="$(detect_platform)"

    # Determine version to install
    if [[ -z "$version" ]]; then
        log_info "Fetching latest opencode version..."
        version="$(get_latest_version)"
    fi
    log_info "Target version: v${version}"

    # Check if already installed with correct version
    if [[ -x "$OPENCODE_BIN" ]]; then
        log_info "opencode binary already exists at $OPENCODE_BIN"
        log_info "Re-installing to ensure version v${version}..."
    fi

    # Determine archive format: Linux uses .tar.gz, macOS uses .zip
    local os_part="${platform%%-*}"
    local archive_ext archive_name
    if [[ "$os_part" == "linux" ]]; then
        archive_ext="tar.gz"
    else
        archive_ext="zip"
    fi
    archive_name="opencode-${platform}.${archive_ext}"

    local download_url="https://github.com/${OPENCODE_REPO}/releases/download/v${version}/${archive_name}"
    local tmp_dir=""
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir:-}"' EXIT

    log_info "Downloading ${archive_name}..."
    curl -fsSL "$download_url" -o "${tmp_dir}/${archive_name}"

    log_info "Extracting..."
    if [[ "$archive_ext" == "tar.gz" ]]; then
        tar -xzf "${tmp_dir}/${archive_name}" -C "$tmp_dir"
    else
        unzip -qo "${tmp_dir}/${archive_name}" -d "$tmp_dir"
    fi

    # Install binary
    mkdir -p "$OPENCODE_BIN_DIR"

    # Find the opencode binary in the extracted contents
    local extracted_bin
    extracted_bin=$(find "$tmp_dir" -name "opencode" -type f -executable 2>/dev/null | head -1)
    if [[ -z "$extracted_bin" ]]; then
        # Try without executable flag (might not be set in archive)
        extracted_bin=$(find "$tmp_dir" -name "opencode" -type f ! -name "*.tar.gz" ! -name "*.zip" 2>/dev/null | head -1)
    fi

    if [[ -z "$extracted_bin" ]]; then
        log_error "Could not find opencode binary in downloaded archive"
        exit 1
    fi

    rm -f "$OPENCODE_BIN"
    cp "$extracted_bin" "$OPENCODE_BIN"
    chmod +x "$OPENCODE_BIN"

    log_success "opencode installed at $OPENCODE_BIN"
}

setup_plugin_runtime() {
    # Create the plugin runtime package.json if not exists
    local pkg_file="$OPENCODE_DIR/package.json"
    if [[ ! -f "$pkg_file" ]]; then
        log_info "Creating plugin runtime package.json..."
        cat > "$pkg_file" <<'EOF'
{
  "dependencies": {
    "@opencode-ai/plugin": "1.3.2"
  }
}
EOF
    fi

    # Install plugin runtime dependencies
    if [[ -d "$OPENCODE_DIR/node_modules/@opencode-ai" ]]; then
        log_info "Plugin runtime already installed"
    else
        log_info "Installing plugin runtime..."
        (cd "$OPENCODE_DIR" && bun install --no-progress)
        log_success "Plugin runtime installed"
    fi
}

main() {
    log_header "Installing OpenCode"

    # Verify dependencies
    require_cmd curl
    require_cmd unzip
    require_cmd jq
    require_cmd bun

    install_opencode
    setup_plugin_runtime

    log_success "OpenCode installation complete"
}

main "$@"
