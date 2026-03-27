#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

MARKER_BEGIN="# >>> env_setup managed >>>"

detect_shell_rc() {
    local shell_name
    shell_name="$(basename "${SHELL:-/bin/bash}")"
    case "$shell_name" in
        bash) echo "$HOME/.bashrc" ;;
        zsh)  echo "$HOME/.zshrc" ;;
        *)    echo "$HOME/.bashrc" ;;
    esac
}

RC_FILE="$(detect_shell_rc)"

echo "Testing Shell Config..."

assert_file_exists "$RC_FILE" "shell rc file exists ($RC_FILE)"
assert_file_contains "$RC_FILE" "$MARKER_BEGIN" "managed block present in rc file"
assert_file_contains "$RC_FILE" 'BUN_INSTALL' "BUN_INSTALL export in rc file"
assert_file_contains "$RC_FILE" '.opencode/bin' "opencode PATH in rc file"
assert_file_contains "$RC_FILE" 'alias omo-spark=' "omo-spark alias in rc file"
assert_file_contains "$RC_FILE" 'alias omo-full=' "omo-full alias in rc file"
assert_file_contains "$RC_FILE" 'alias omo-debug=' "omo-debug alias in rc file"
assert_file_contains "$RC_FILE" 'alias omo-current=' "omo-current alias in rc file"

print_test_summary
