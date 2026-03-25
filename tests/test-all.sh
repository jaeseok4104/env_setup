#!/usr/bin/env bash
# Run all test suites and report aggregate results
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

SUITES_PASSED=0
SUITES_FAILED=0
FAILED_SUITES=()

echo -e "${BOLD}Running all tests...${NC}"
echo ""

for test_file in "${SCRIPT_DIR}"/test-*.sh; do
    [[ "$(basename "$test_file")" == "test-all.sh" ]] && continue
    suite_name="$(basename "$test_file" .sh)"
    echo -e "${BOLD}[$suite_name]${NC}"

    if bash "$test_file"; then
        SUITES_PASSED=$((SUITES_PASSED + 1))
    else
        SUITES_FAILED=$((SUITES_FAILED + 1))
        FAILED_SUITES+=("$suite_name")
    fi
    echo ""
done

echo -e "${BOLD}════════════════════════════════════════${NC}"
echo -e "${BOLD}  Test Results${NC}"
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo ""

total=$((SUITES_PASSED + SUITES_FAILED))
echo "  Suites: $SUITES_PASSED/$total passed"

if [[ "$SUITES_FAILED" -gt 0 ]]; then
    echo -e "  ${RED}Failed:${NC} ${FAILED_SUITES[*]}"
    echo ""
    exit 1
else
    echo -e "  ${GREEN}All suites passed!${NC}"
    echo ""
    exit 0
fi
