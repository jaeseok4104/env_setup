#!/usr/bin/env bash
# Master setup script: installs opencode, omo, ghostty, and docker with full configuration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/_common.sh"

SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

DRY_RUN=false
FORCE=false
SKIP_DEPS=false
SKIP_OPENCODE=false
SKIP_OMO=false
SKIP_GHOSTTY=false
SKIP_DOCKER=false
SKIP_SHELL=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install and configure opencode, omo, ghostty, and docker.

Options:
    --dry-run           Show what would be done without executing
    --force             Overwrite existing config files
    --skip-deps         Skip dependency installation
    --skip-opencode     Skip opencode installation
    --skip-omo          Skip OMO installation
    --skip-ghostty      Skip Ghostty installation
    --skip-docker       Skip Docker installation
    --skip-shell        Skip shell configuration
    -h, --help          Show this help message
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)      DRY_RUN=true ;;
            --force|-f)     FORCE=true ;;
            --skip-deps)    SKIP_DEPS=true ;;
            --skip-opencode) SKIP_OPENCODE=true ;;
            --skip-omo)     SKIP_OMO=true ;;
            --skip-ghostty) SKIP_GHOSTTY=true ;;
            --skip-docker)  SKIP_DOCKER=true ;;
            --skip-shell)   SKIP_SHELL=true ;;
            -h|--help)      usage; exit 0 ;;
            *)              log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done
}

run_step() {
    local name="$1"
    local script="$2"
    shift 2

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would run: $script $*"
        return 0
    fi

    bash "$script" "$@" || {
        log_error "Step failed: $name"
        log_error "  Script: $script"
        exit 1
    }
}

main() {
    parse_args "$@"

    log_header "Environment Setup"
    log_info "Platform: $(uname -s) $(uname -m)"
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    local steps_run=0
    local steps_skipped=0

    if [[ "$SKIP_DEPS" == "false" ]]; then
        run_step "Dependencies" "${SCRIPTS_DIR}/install-dependencies.sh"
        steps_run=$((steps_run + 1))
    else
        log_info "[SKIP] Dependencies"
        steps_skipped=$((steps_skipped + 1))
    fi

    if [[ "$SKIP_OPENCODE" == "false" ]]; then
        run_step "OpenCode" "${SCRIPTS_DIR}/install-opencode.sh"
        steps_run=$((steps_run + 1))
    else
        log_info "[SKIP] OpenCode"
        steps_skipped=$((steps_skipped + 1))
    fi

    if [[ "$SKIP_OMO" == "false" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            run_step "OMO" "${SCRIPTS_DIR}/install-omo.sh" "--force"
        else
            run_step "OMO" "${SCRIPTS_DIR}/install-omo.sh"
        fi
        steps_run=$((steps_run + 1))
    else
        log_info "[SKIP] OMO"
        steps_skipped=$((steps_skipped + 1))
    fi

    if [[ "$SKIP_GHOSTTY" == "false" ]]; then
        run_step "Ghostty" "${SCRIPTS_DIR}/install-ghostty.sh"
        steps_run=$((steps_run + 1))
    else
        log_info "[SKIP] Ghostty"
        steps_skipped=$((steps_skipped + 1))
    fi

    if [[ "$SKIP_DOCKER" == "false" ]]; then
        run_step "Docker" "${SCRIPTS_DIR}/install-docker.sh"
        steps_run=$((steps_run + 1))
    else
        log_info "[SKIP] Docker"
        steps_skipped=$((steps_skipped + 1))
    fi

    if [[ "$SKIP_SHELL" == "false" ]]; then
        run_step "Shell Config" "${SCRIPTS_DIR}/setup-shell.sh"
        steps_run=$((steps_run + 1))
    else
        log_info "[SKIP] Shell Config"
        steps_skipped=$((steps_skipped + 1))
    fi

    echo ""
    log_header "Setup Complete"
    log_success "Steps run: $steps_run | Skipped: $steps_skipped"
    echo ""
    log_info "Next steps:"
    log_info "  1. source ~/.bashrc  (or restart your shell)"
    log_info "  2. opencode          (first run will prompt for auth)"
    log_info "  3. ghostty           (launch terminal)"
    echo ""
}

main "$@"
