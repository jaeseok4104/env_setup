#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

CONFIG_DIR="$HOME/.config/opencode"

echo "Testing OMO..."

assert_dir_exists "$CONFIG_DIR" "opencode config directory exists"

for config in opencode.json oh-my-opencode.json oh-my-opencode-copilot.json oh-my-opencode.full.json oh-my-opencode.spark.json; do
    assert_file_exists "$CONFIG_DIR/$config" "$config deployed"
    assert_json_valid "$CONFIG_DIR/$config" "$config is valid JSON"
done

assert_json_has_key "$CONFIG_DIR/opencode.json" '.plugin' "opencode.json has plugin key"
assert_json_has_key "$CONFIG_DIR/oh-my-opencode.json" '.agents' "oh-my-opencode.json has agents key"
assert_json_has_key "$CONFIG_DIR/oh-my-opencode.json" '.agents.sisyphus' "oh-my-opencode.json has sisyphus agent"
assert_json_has_key "$CONFIG_DIR/oh-my-opencode.json" '.agents.oracle' "oh-my-opencode.json has oracle agent"

assert_dir_exists "$CONFIG_DIR/node_modules" "plugin node_modules installed"

print_test_summary
