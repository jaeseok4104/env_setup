#!/usr/bin/env bash
# Test helpers: assertion functions for test scripts
set -euo pipefail

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

_inc() { eval "$1=\$((\$$1 + 1))"; }

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_cmd_exists() {
    local cmd="$1"
    local desc="${2:-$cmd exists in PATH}"
    _inc TESTS_TOTAL

    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}: $desc"
        _inc TESTS_PASSED
    else
        echo -e "  ${RED}FAIL${NC}: $desc"
        _inc TESTS_FAILED
    fi
}

assert_file_exists() {
    local file="$1"
    local desc="${2:-$file exists}"
    _inc TESTS_TOTAL

    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}PASS${NC}: $desc"
        _inc TESTS_PASSED
    else
        echo -e "  ${RED}FAIL${NC}: $desc"
        _inc TESTS_FAILED
    fi
}

assert_dir_exists() {
    local dir="$1"
    local desc="${2:-$dir exists}"
    _inc TESTS_TOTAL

    if [[ -d "$dir" ]]; then
        echo -e "  ${GREEN}PASS${NC}: $desc"
        _inc TESTS_PASSED
    else
        echo -e "  ${RED}FAIL${NC}: $desc"
        _inc TESTS_FAILED
    fi
}

assert_file_executable() {
    local file="$1"
    local desc="${2:-$file is executable}"
    _inc TESTS_TOTAL

    if [[ -x "$file" ]]; then
        echo -e "  ${GREEN}PASS${NC}: $desc"
        _inc TESTS_PASSED
    else
        echo -e "  ${RED}FAIL${NC}: $desc"
        _inc TESTS_FAILED
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local desc="${3:-$file contains '$pattern'}"
    _inc TESTS_TOTAL

    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}: $desc"
        _inc TESTS_PASSED
    else
        echo -e "  ${RED}FAIL${NC}: $desc"
        _inc TESTS_FAILED
    fi
}

assert_json_valid() {
    local file="$1"
    local desc="${2:-$file is valid JSON}"
    _inc TESTS_TOTAL

    if jq empty "$file" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}: $desc"
        _inc TESTS_PASSED
    else
        echo -e "  ${RED}FAIL${NC}: $desc"
        _inc TESTS_FAILED
    fi
}

assert_json_has_key() {
    local file="$1"
    local key="$2"
    local desc="${3:-$file has key '$key'}"
    _inc TESTS_TOTAL

    if jq -e "$key" "$file" &>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}: $desc"
        _inc TESTS_PASSED
    else
        echo -e "  ${RED}FAIL${NC}: $desc"
        _inc TESTS_FAILED
    fi
}

print_test_summary() {
    echo ""
    echo "────────────────────────"
    if [[ "$TESTS_FAILED" -eq 0 ]]; then
        echo -e "${GREEN}All $TESTS_TOTAL tests passed${NC}"
    else
        echo -e "${RED}$TESTS_FAILED/$TESTS_TOTAL tests failed${NC}"
    fi
    echo "────────────────────────"
    return "$TESTS_FAILED"
}
