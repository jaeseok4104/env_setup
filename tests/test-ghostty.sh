#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

echo "Testing Ghostty..."

if command -v ghostty &>/dev/null || snap list ghostty &>/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${NC}: ghostty is installed"
    _inc TESTS_PASSED
    _inc TESTS_TOTAL
else
    echo -e "  ${RED}FAIL${NC}: ghostty is installed"
    _inc TESTS_FAILED
    _inc TESTS_TOTAL
fi

assert_dir_exists "$HOME/.config/ghostty" "ghostty config directory exists"

_inc TESTS_TOTAL
DEFAULT_TERMINAL=$(update-alternatives --query x-terminal-emulator 2>/dev/null | grep "^Value:" | awk '{print $2}' || echo "")
if [[ "$DEFAULT_TERMINAL" == "/snap/bin/ghostty" ]]; then
    echo -e "  ${GREEN}PASS${NC}: ghostty is the default terminal"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: ghostty is the default terminal (current: ${DEFAULT_TERMINAL:-none})"
    _inc TESTS_FAILED
fi

print_test_summary
