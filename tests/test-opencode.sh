#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

OPENCODE_BIN="$HOME/.opencode/bin/opencode"

echo "Testing OpenCode..."

assert_file_exists "$OPENCODE_BIN" "opencode binary exists"
assert_file_executable "$OPENCODE_BIN" "opencode binary is executable"
assert_dir_exists "$HOME/.opencode/node_modules" "plugin runtime node_modules exists"
assert_file_exists "$HOME/.opencode/package.json" "plugin runtime package.json exists"

print_test_summary
