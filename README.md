# Privama

Privama is a **Privacy-first local AI dev toolkit and installation workflow with Ollama**, designed to empower the new wave of modern lazy developers to write and run AI-assisted code with **privacy and control built in from the start**.

This repo also has a simple but powerful installer script that sets up the Ollama AI platform, privacy configurations, and commonly used tools, enabling users to code freely without compromising their data or telemetry.

---

## Vision

Privama is a toolkit and workflow for developers seeking to **vibe code with privacy and confidence**.  
By combining AI models with network lockdown, history management, firewall configuration, and environment isolation, Privama helps users:

- Work with AI models locally without unintentional data leakage  
- Maintain control over network access and model usage  
- Easily clear command histories and restrict data access  
- Revert privacy settings cleanly anytime  
- Quickly get started with minimal setup hassle

## Table of Contents
- [Install Ollama](#install-ollama)
- [Pull and Run Models](#pull-and-run-models)
- [Manual Installation](#manual-installation)
- [Setup on RedHat/CentOS/Fedora](#setup-on-redhatcentosfedora)
- [Setup on Debian/Ubuntu](#setup-on-debianubuntu)
- [Setup on macOS](#setup-on-macos)
- [GPU Acceleration](#gpu-acceleration)
- [Configuring Ollama Service for Docker Networking](#configuring-ollama-service-for-docker-networking)
- [Privacy Commands to Sandbox Ollama after Installation](#privacy-commands-to-sandbox-ollama-after-installation)
- [Using the Privama.sh Script](#using-the-privamash-script)
***

# Privama Environment Manual Installation & Usage Guide
This guide provides detailed instructions to install Ollama on Linux, pull and run models, and integrate the Open-WebUI for enhanced user experience.


## Install Ollama
Run the official installer script, which automatically detects your system architecture and configures Ollama:
```
curl -fsSL https://ollama.com/install.sh | sh
```
- Install Ollama and pull multiple models
```
curl -fsSL https://ollama.com/install.sh | sh && ollama pull llama2-uncensored:7b dolphin-mistral:7b
```
- Install Ollama and run specific model
```
curl -fsSL https://ollama.com/install.sh | sh && ollama run llama2-uncensored:7b
```
After installation, verify by running:
```
ollama --version
```


## Pull and Run Models
- Pull one or multiple models:
```
ollama pull llama2-uncensored:7b
ollama pull llama2-uncensored:7b dolphin-mistral:7b
```
- Run a specific model:
```
ollama run llama2-uncensored:7b
```
***

## Setup on RedHat / CentOS / Fedora
Install Ollama, Void and run specific model
```
curl -fsSL https://ollama.com/install.sh | sh && sudo dnf install -y wget jq && \
LATEST_RPM_URL=$(wget -qO- https://api.github.com/repos/voideditor/binaries/releases/latest | jq -r '.assets[] | select(.name | test("x86_64\\.rpm$")) | .browser_download_url') && wget -O void.rpm "$LATEST_RPM_URL" && \
sudo dnf install -y ./void.rpm && \
ollama run llama2-uncensored:7b
```
Install Ollama, Void editor, and Open-WebUI with these commands:
```
curl -fsSL https://ollama.com/install.sh | sh && sudo dnf install -y wget jq && \
LATEST_RPM_URL=$(wget -qO- https://api.github.com/repos/voideditor/binaries/releases/latest | jq -r '.assets[] | select(.name | test("x86_64\\.rpm$")) | .browser_download_url') && wget -O void.rpm "$LATEST_RPM_URL" && \
sudo dnf install -y ./void.rpm && \
ollama run llama2-uncensored:7b && \
sudo usermod -aG docker $USER && \
newgrp docker <<EOF
docker run -d -p 3000:3000 -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434 --name open-webui ghcr.io/open-webui/open-webui:main
EOF
```


## Setup on Debian / Ubuntu
Install Ollama, Void and run specific model
```
curl -fsSL https://ollama.com/install.sh | sh && sudo apt-get update && sudo apt-get install -y wget jq && \
LATEST_DEB_URL=$(wget -qO- https://api.github.com/repos/voideditor/binaries/releases/latest | jq -r '.assets[] | select(.name | test("amd64.deb$")) | .browser_download_url') && \
wget -O void.deb "$LATEST_DEB_URL" && \
sudo apt-get install -y ./void.deb && \
ollama run llama2-uncensored:7b
```
Similarly, install Ollama, Void editor, and Open-WebUI on Debian-based systems:
```
curl -fsSL https://ollama.com/install.sh | sh && sudo apt-get update && sudo apt-get install -y wget jq && \
LATEST_DEB_URL=$(wget -qO- https://api.github.com/repos/voideditor/binaries/releases/latest | jq -r '.assets[] | select(.name | test("amd64.deb$")) | .browser_download_url') && \
wget -O void.deb "$LATEST_DEB_URL" && \
sudo apt-get install -y ./void.deb && \
sudo usermod -aG docker $USER && \
newgrp docker <<EOF
docker run -d -p 3000:3000 -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434 --name open-webui ghcr.io/open-webui/open-webui:main
EOF
```

## Setup on macOS
- Install Ollama, Void and run specific model
```
brew install ollama && ollama pull llama2-uncensored:7b && ollama run llama2-uncensored:7b
```
- Install Ollama, Void editor, and Open-WebUI
```
brew install ollama && ollama pull llama2-uncensored:7b && ollama run llama2-uncensored:7b && \
brew install --cask docker && open /Applications/Docker.app && \
docker run -d -p 3000:3000 -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434 --name open-webui ghcr.io/open-webui/open-webui:main
```
***

## GPU Acceleration
If your system has a compatible GPU (NVIDIA/AMD), enable GPU acceleration for Open-WebUI by adding the `--gpus=all` option:
```
docker run -d --gpus=all -p 3000:3000 \\
  -e OLLAMA_API_BASE_URL=http://host.docker.internal:11434 \\
  --name open-webui ghcr.io/open-webui/open-webui:main
```
***

## Configuring Ollama Service for Docker Networking
To allow Docker containers to access the Ollama service, configure Ollama’s systemd service with the correct host IP.
1. Edit the Ollama service file:
```
sudo nano /etc/systemd/system/ollama.service
```
2. Add this line under the `[Service]` section:
```
Environment="OLLAMA_HOST=172.17.0.1"
```
3. Save and exit (Ctrl+O, Enter, Ctrl+X).
4. Reload systemd and restart Ollama:
```
sudo systemctl daemon-reload
sudo systemctl restart ollama
```
***

## Privacy Commands to Sandbox Ollama after Installation

Once Ollama and related tools are installed, you can manually sandbox Ollama’s network access for privacy using these convenient firewall commands. This lets you ensure chats remain local and prevent unintended data leaks.

### Block Only Ollama’s Internet Access (Recommended)

This blocks only outgoing traffic to the default Ollama API port (11434), so Ollama cannot connect to external servers, but your system remains fully online.

- **On macOS (using pf):**
```
echo "block drop out proto tcp from any to any port 11434" | sudo tee /etc/pf.privama.conf
sudo pfctl -f /etc/pf.privama.conf
sudo pfctl -E
```

- **On Linux (using iptables):**
```
sudo iptables -A OUTPUT -p tcp --dport 11434 -m comment --comment "privama-ollama" -j REJECT
```

### Block All Outbound Internet for the Current User (Advanced and Risky)

This disables all outbound network traffic for your current user, providing maximum isolation for Ollama but may disrupt other applications.

- **On macOS (using pf):**
```
echo "block drop out all" | sudo tee /etc/pf.privama.conf
sudo pfctl -f /etc/pf.privama.conf
sudo pfctl -E
```

- **On Linux (using iptables):**
```
MY_UID=$(id -u)
sudo iptables -A OUTPUT -m owner --uid-owner "$MY_UID" -m comment --comment "privama-all" -j REJECT
```

### Removing Firewall Blocking Rules

If you want to remove the rules and restore full network functionality, run:

- **On macOS:**
```
sudo pfctl -d
sudo rm -f /etc/pf.privama.conf
```

- **On Linux:**
```
MY_UID=$(id -u)
sudo iptables -D OUTPUT -p tcp --dport 11434 -m comment --comment "privama-ollama" -j REJECT 2>/dev/null || true
sudo iptables -D OUTPUT -m owner --uid-owner "$MY_UID" -m comment --comment "privama-all" -j REJECT 2>/dev/null || true
```

---

### Notes

- The recommended firewall command is to block *only Ollama’s port* (11434) to minimize risk of system-wide network disruption.  
- Blocking all outbound traffic is only advised for advanced users who understand the implications.  
- After applying firewall rules, test your network and Ollama locally to confirm expected behavior.  
- These commands mirror the default "firewall" privacy functionality in the `privama.sh` script for those who prefer manual control.

---
***

# Using the Privama.sh Script

The `privama.sh` script helps install Ollama with privacy in mind by automating installation, model pulling, optional Open-WebUI setup, and sandboxing Ollama’s internet access via firewall rules.

### How to run

1. Download the `privama.sh` or clone this repo into your desired sytem/location.
2. Make it executable:
```
chmod +x privama.sh
```
3. Run the script:
```
./privama.sh
```

### What the script does:

- Detects your OS and installs Ollama appropriately (macOS, Debian/Ubuntu, Fedora/RHEL).  
- Prompts you to select which Ollama models to pull.  
- Optionally installs and runs Open-WebUI in Docker.  
- Clears Ollama history files and locks down permissions.  
- Applies firewall rules to block Ollama’s internet connection (recommended), or optionally block all your system’s outbound internet with clear warnings.  
- Allows resetting/removal of firewall rules.

### Important points:

- The default firewall option blocks only Ollama’s port (11434) for privacy without cutting off your entire system internet.  
- Disabling all system network interfaces is **not enabled** by default to prevent accidental lockouts.  
- The script logs actions clearly and asks for confirmation at each step.

This script is designed to give you privacy sandboxing while keeping your system fully online and accessible.

If unsure, select the recommended firewall option to block only Ollama traffic.
