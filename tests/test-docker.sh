#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Testing Docker..."

assert_cmd_exists docker "docker is installed"

_inc TESTS_TOTAL
if docker compose version &>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}: docker compose plugin is available"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: docker compose plugin is available"
    _inc TESTS_FAILED
fi

_inc TESTS_TOTAL
if id -nG "$(whoami)" | grep -qw docker; then
    echo -e "  ${GREEN}PASS${NC}: user is in docker group"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: user is in docker group"
    _inc TESTS_FAILED
fi

_inc TESTS_TOTAL
if systemctl is-active --quiet docker 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}: docker service is active"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: docker service is active"
    _inc TESTS_FAILED
fi

assert_file_exists /etc/docker/daemon.json "docker daemon.json exists"
assert_json_valid /etc/docker/daemon.json "docker daemon.json is valid JSON"
assert_json_has_key /etc/docker/daemon.json ".runtimes.nvidia" "daemon.json has NVIDIA runtime configured"

assert_file_exists "${REPO_ROOT}/configs/docker-daemon.json" "docker-daemon.json config template exists"
assert_json_valid "${REPO_ROOT}/configs/docker-daemon.json" "docker-daemon.json template is valid JSON"

assert_file_exists /etc/apt/sources.list.d/docker.sources "Docker APT source exists"
assert_file_contains /etc/apt/sources.list.d/docker.sources "download.docker.com" "Docker APT source points to official repo"

_inc TESTS_TOTAL
if dpkg -s docker-ce &>/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${NC}: docker-ce package is installed"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: docker-ce package is installed"
    _inc TESTS_FAILED
fi

_inc TESTS_TOTAL
if dpkg -s docker-compose-plugin &>/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${NC}: docker-compose-plugin package is installed"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: docker-compose-plugin package is installed"
    _inc TESTS_FAILED
fi

print_test_summary
