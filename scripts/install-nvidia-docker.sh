#!/usr/bin/env bash
# Install NVIDIA Container Toolkit for Docker GPU support
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

NVIDIA_KEYRING="/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
NVIDIA_APT_LIST="/etc/apt/sources.list.d/nvidia-container-toolkit.list"

NVIDIA_PACKAGES=(
    nvidia-container-toolkit
)

check_nvidia_gpu() {
    if ! command -v nvidia-smi &>/dev/null; then
        log_warn "nvidia-smi not found — NVIDIA driver may not be installed"
        log_warn "Skipping NVIDIA Container Toolkit installation"
        return 1
    fi

    local gpu_name
    gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1) || true
    if [[ -z "$gpu_name" ]]; then
        log_warn "No NVIDIA GPU detected — skipping"
        return 1
    fi

    log_info "Detected GPU: $gpu_name"
    return 0
}

setup_nvidia_apt_repo() {
    if [[ ! -f "$NVIDIA_KEYRING" ]]; then
        log_info "Adding NVIDIA Container Toolkit GPG key..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
            | sudo gpg --dearmor -o "$NVIDIA_KEYRING"
        sudo chmod a+r "$NVIDIA_KEYRING"
        log_success "NVIDIA GPG key added: $NVIDIA_KEYRING"
    else
        log_info "NVIDIA GPG key already exists: $NVIDIA_KEYRING"
    fi

    if [[ ! -f "$NVIDIA_APT_LIST" ]]; then
        log_info "Adding NVIDIA Container Toolkit APT repository..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
            | sed "s#deb https://#deb [signed-by=${NVIDIA_KEYRING}] https://#g" \
            | sudo tee "$NVIDIA_APT_LIST" > /dev/null
        sudo apt-get update -qq
        log_success "NVIDIA APT source added: $NVIDIA_APT_LIST"
    else
        log_info "NVIDIA APT source already exists: $NVIDIA_APT_LIST"
    fi
}

install_nvidia_packages() {
    local to_install=()

    for pkg in "${NVIDIA_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing NVIDIA Container Toolkit packages: ${to_install[*]}"
        sudo apt-get install -y -qq "${to_install[@]}"
        log_success "NVIDIA Container Toolkit packages installed"
    else
        log_info "NVIDIA Container Toolkit already installed"
    fi
}

configure_docker_nvidia_runtime() {
    if ! command -v nvidia-ctk &>/dev/null; then
        log_error "nvidia-ctk not found after installation"
        return 1
    fi

    local daemon_config="/etc/docker/daemon.json"
    local needs_configure=false
    local needs_restart=false

    if [[ ! -f "$daemon_config" ]]; then
        needs_configure=true
    elif ! jq -e '.runtimes.nvidia' "$daemon_config" &>/dev/null; then
        needs_configure=true
    fi

    if [[ "$needs_configure" == "true" ]]; then
        log_info "Configuring Docker NVIDIA runtime via nvidia-ctk..."
        sudo nvidia-ctk runtime configure --runtime=docker
        log_success "Docker NVIDIA runtime configured"
        needs_restart=true
    else
        log_info "Docker NVIDIA runtime already configured in $daemon_config"
    fi

    # Set nvidia as default runtime to avoid CDI scan issues on hybrid GPU systems
    # (e.g. AMD iGPU + NVIDIA dGPU where --gpus flag triggers "AMD CDI spec not found")
    if [[ -f "$daemon_config" ]] && ! jq -e '.["default-runtime"] == "nvidia"' "$daemon_config" &>/dev/null; then
        log_info "Setting nvidia as default Docker runtime..."
        local tmp_config
        tmp_config=$(jq '. + {"default-runtime": "nvidia"}' "$daemon_config")
        echo "$tmp_config" | sudo tee "$daemon_config" > /dev/null
        log_success "Default runtime set to nvidia"
        needs_restart=true
    fi

    if [[ "$needs_restart" == "true" ]] && systemctl is-active --quiet docker; then
        log_info "Restarting Docker to apply runtime changes..."
        sudo systemctl restart docker
        log_success "Docker restarted"
    fi
}

generate_cdi_spec() {
    local cdi_spec="/etc/cdi/nvidia.yaml"

    if [[ -f "$cdi_spec" ]]; then
        log_info "CDI spec already exists: $cdi_spec"
        return 0
    fi

    log_info "Generating NVIDIA CDI spec for --gpus flag support..."
    sudo mkdir -p /etc/cdi
    sudo nvidia-ctk cdi generate --output="$cdi_spec"
    log_success "CDI spec generated: $cdi_spec"
}

verify_nvidia_docker() {
    log_info "Verifying NVIDIA Docker runtime..."

    if ! docker info 2>/dev/null | grep -q "nvidia"; then
        log_warn "NVIDIA runtime not visible in docker info — Docker restart may be needed"
        return 0
    fi

    log_success "NVIDIA runtime registered in Docker"
}

main() {
    log_header "Installing NVIDIA Container Toolkit"

    require_cmd curl
    require_cmd docker

    if ! check_nvidia_gpu; then
        log_warn "NVIDIA Container Toolkit installation skipped (no GPU)"
        return 0
    fi

    setup_nvidia_apt_repo
    install_nvidia_packages
    configure_docker_nvidia_runtime
    generate_cdi_spec
    verify_nvidia_docker

    log_success "NVIDIA Container Toolkit installation complete"
}

main "$@"
