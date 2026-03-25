#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

echo "Testing Dependencies..."

assert_cmd_exists curl "curl is installed"
assert_cmd_exists unzip "unzip is installed"
assert_cmd_exists jq "jq is installed"
assert_cmd_exists snap "snap is installed"
assert_cmd_exists node "node is installed"

if command -v bun &>/dev/null || [[ -x "$HOME/.bun/bin/bun" ]]; then
    echo -e "  ${GREEN}PASS${NC}: bun is installed"
    _inc TESTS_PASSED
    _inc TESTS_TOTAL
else
    echo -e "  ${RED}FAIL${NC}: bun is installed"
    _inc TESTS_FAILED
    _inc TESTS_TOTAL
fi

print_test_summary
