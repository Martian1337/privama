#!/usr/bin/env bash
set -euo pipefail

# === Colors === #
GREEN="\\033[0;32m"; RED="\\033[0;31m"; YELLOW="\\033[1;33m"; RESET="\\033[0m"
log() { echo -e "${GREEN}[+]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
err() { echo -e "${RED}[x]${RESET} $*" >&2; }

# === Detect OS/Distro === #
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
DISTRO=""
if [[ "$OS" == "linux" ]]; then
    if [ -f /etc/os-release ]; then 
        . /etc/os-release 
        DISTRO="${ID,,}"
    else 
        DISTRO="unknown"
    fi
elif [[ "$OS" == "darwin" ]]; then
    DISTRO="macos"
else
    err "Unsupported OS: $OS"
    exit 1
fi
log "Detected platform: $DISTRO"

# === Detect proper API URL for WebUI Docker === #
detect_ollama_api_url() {
    if [[ "$DISTRO" == "macos" ]]; then
        echo "host.docker.internal"
    else
        if ping -c1 -W1 host.docker.internal &>/dev/null; then
            echo "host.docker.internal"
        else
            ip route | awk '/default/ {print $3; exit}' || echo "172.17.0.1"
        fi
    fi
}

# === Install Ollama === #
install_ollama() {
    if [[ "$DISTRO" == "macos" ]]; then
        if command -v ollama >/dev/null 2>&1; then
            log "Ollama already installed, skipping."
        elif command -v brew >/dev/null 2>&1; then
            log "Installing Ollama via Homebrew..."
            brew install ollama
        else
            log "Downloading official Ollama for macOS..."
            curl -LO https://ollama.com/download/Ollama-darwin.zip
            unzip Ollama-darwin.zip -d /Applications
            rm Ollama-darwin.zip
        fi
    elif [[ "$DISTRO" =~ debian|ubuntu|linuxmint|pop ]]; then
        if command -v ollama >/dev/null 2>&1; then
            log "Ollama already installed, skipping."
        else
            curl -fsSL https://ollama.com/install.sh | sh
            sudo apt-get update && sudo apt-get install -y wget jq docker.io || true
        fi
    elif [[ "$DISTRO" =~ fedora|centos|rhel|rocky|almalinux ]]; then
        if command -v ollama >/dev/null 2>&1; then
            log "Ollama already installed, skipping."
        else
            curl -fsSL https://ollama.com/install.sh | sh
            sudo dnf install -y wget jq docker || true
        fi
    else
        err "Unsupported distribution: $DISTRO"
        exit 1
    fi
}

# === Models === #
prompt_for_models() {
    echo "Browse available models: https://ollama.com/search"
    read -rp "Pull models now? (y/n): " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { warn "Skipping model pulls."; return; }
    read -rp "Enter models (e.g. codellama:7b gemma2:27b): " MODELS
    for M in $MODELS; do ollama pull "$M"; done
}

# === Open-WebUI === #
install_webui() {
    OLLAMA_HOST=$(detect_ollama_api_url)
    log "Using OLLAMA_API_BASE_URL=http://$OLLAMA_HOST:11434"
    sudo docker run -d -p 3000:3000 \
        -e OLLAMA_API_BASE_URL=http://$OLLAMA_HOST:11434 \
        --name open-webui ghcr.io/open-webui/open-webui:main
}

# === Manage History === #
manage_history() {
    OLLAMA_DIR="${OLLAMA_DIR:-$HOME/.ollama}"
    HISTFILE="$OLLAMA_DIR/history"
    [ -f "$HISTFILE" ] && rm -f "$HISTFILE"
    chmod -R go-rwx "$OLLAMA_DIR" 2>/dev/null || true
    chown -R "$(whoami)" "$OLLAMA_DIR" 2>/dev/null || true
    log "History cleared and directory locked down."
}

# === Firewall Setup === #
manage_firewall() {
    echo "Firewall Privacy Options:"
    echo "1) Block ONLY Ollama traffic (recommended)"
    echo "2) Block ALL outbound Internet traffic (advanced, may break system!)"
    echo "3) Skip firewall configuration"
    read -rp "Select option (1-3): " FWCHOICE

    if [[ "$DISTRO" == "macos" ]]; then
        case $FWCHOICE in
            1) PF_RULE="block drop out proto tcp from any to any port 11434"
               log "Selected: Block Ollama port only." ;;
            2) warn "⚠️ This will cut off all internet traffic from your Mac!"
               PF_RULE="block drop out all" ;;
            3) warn "Skipping firewall setup."; return ;;
            *) warn "Invalid choice. Skipping firewall setup."; return ;;
        esac
        PF_CONF="/etc/pf.privama.conf"
        echo "$PF_RULE" | sudo tee "$PF_CONF" >/dev/null
        sudo pfctl -f "$PF_CONF"
        sudo pfctl -E
        log "pf firewall rule applied."

    else
        case $FWCHOICE in
            1)
                sudo iptables -A OUTPUT -p tcp --dport 11434 -m comment --comment "privama-ollama" -j REJECT
                log "iptables rule applied (Ollama port 11434 blocked)." ;;
            2)
                warn "⚠️ This will block ALL outbound traffic for your user!"
                MY_UID=$(id -u)
                sudo iptables -A OUTPUT -m owner --uid-owner "$MY_UID" -m comment --comment "privama-all" -j REJECT
                log "iptables rule applied (all outbound traffic blocked for uid=$MY_UID)." ;;
            3) warn "Skipping firewall setup."; return ;;
            *) warn "Invalid choice. Skipping firewall setup."; return ;;
        esac
    fi
}

# === Firewall Reset === #
reset_firewall() {
    if [[ "$DISTRO" == "macos" ]]; then
        log "Resetting pf firewall rules..."
        sudo pfctl -d || true
        sudo rm -f /etc/pf.privama.conf || true
        log "pf firewall reset complete."
    else
        MY_UID=$(id -u)
        log "Removing privama rules from iptables..."
        sudo iptables -D OUTPUT -p tcp --dport 11434 -m comment --comment "privama-ollama" -j REJECT 2>/dev/null || true
        sudo iptables -D OUTPUT -m owner --uid-owner "$MY_UID" -m comment --comment "privama-all" -j REJECT 2>/dev/null || true
        log "iptables privama rules removed."
    fi
}

# === Main Flow === #
install_ollama
prompt_for_models
read -rp "Install Open-WebUI in Docker? (y/n): " WUI
[[ "$WUI" =~ ^[Yy]$ ]] && install_webui
read -rp "Clear Ollama history now? (y/n): " HIST
[[ "$HIST" =~ ^[Yy]$ ]] && manage_history
read -rp "Add firewall block for Ollama/external calls? (y/n): " FW
[[ "$FW" =~ ^[Yy]$ ]] && manage_firewall

log "=== Installation & Privacy setup complete ==="
read -rp "Do you want to reset/uninstall Privama firewall rules? (y/n): " RESET_FW
[[ "$RESET_FW" =~ ^[Yy]$ ]] && reset_firewall

log "Done. Privama setup/cleanup complete."
exit 0
