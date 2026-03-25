#!/usr/bin/env bash
# Common utility functions shared across all install scripts
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_header() {
    echo ""
    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $*${NC}"
    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo ""
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        local alt_paths=(
            "$HOME/.bun/bin/$cmd"
            "$HOME/.opencode/bin/$cmd"
            "/snap/bin/$cmd"
        )
        for alt in "${alt_paths[@]}"; do
            if [[ -x "$alt" ]]; then
                return 0
            fi
        done
        log_error "Required command not found: $cmd"
        log_error "Run scripts/install-dependencies.sh first"
        exit 1
    fi
}
