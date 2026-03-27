#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_helpers.sh"

echo "Testing NVIDIA Container Toolkit..."

assert_cmd_exists nvidia-container-runtime "nvidia-container-runtime is installed"
assert_cmd_exists nvidia-ctk "nvidia-ctk is installed"

assert_file_exists /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg "NVIDIA GPG keyring exists"
assert_file_exists /etc/apt/sources.list.d/nvidia-container-toolkit.list "NVIDIA APT source exists"
assert_file_contains /etc/apt/sources.list.d/nvidia-container-toolkit.list "nvidia.github.io" "NVIDIA APT source points to official repo"

_inc TESTS_TOTAL
if dpkg -s nvidia-container-toolkit &>/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${NC}: nvidia-container-toolkit package is installed"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: nvidia-container-toolkit package is installed"
    _inc TESTS_FAILED
fi

assert_file_exists /etc/docker/daemon.json "docker daemon.json exists"
assert_json_has_key /etc/docker/daemon.json ".runtimes.nvidia" "daemon.json has NVIDIA runtime configured"

assert_file_exists /etc/cdi/nvidia.yaml "CDI spec exists for --gpus flag support"

_inc TESTS_TOTAL
if docker info 2>/dev/null | grep -q "nvidia"; then
    echo -e "  ${GREEN}PASS${NC}: NVIDIA runtime visible in docker info"
    _inc TESTS_PASSED
else
    echo -e "  ${RED}FAIL${NC}: NVIDIA runtime visible in docker info"
    _inc TESTS_FAILED
fi

print_test_summary
