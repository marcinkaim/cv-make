#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2026 Marcin Kaim
# SPDX-License-Identifier: Apache-2.0
#
# CV Make - install.sh
# Zero-privilege, rootless production installer for Linux environments.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
TARGET_WRAPPER="$BIN_DIR/cv-make"

CONTAINER_IMAGE="ghcr.io/marcinkaim/cv-make:latest"
RELEASE_VERSION="v1.0.0"
RELEASE_URL="https://github.com/marcinkaim/cv-make/releases/download/${RELEASE_VERSION}/cv-make-linux-amd64.tar.gz"

detect_engine() {
    if command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
        echo "podman"
    elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        echo "docker"
    else
        echo ""
    fi
}

show_help() {
    echo "CV Make Linux Production Installer"
    echo "Usage:"
    echo "  ./install.sh                Install CV Make for current user"
    echo "  ./install.sh --reinstall    Force reinstall CV Make wrapper and pull container image"
    echo "  ./install.sh --help         Show this help message"
}

REINSTALL=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --reinstall)
            REINSTALL=1
            shift
            ;;
        *)
            echo "[ERROR] Unknown option: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

ENGINE=$(detect_engine)

if [ -z "$ENGINE" ]; then
    echo "[ERROR] Neither Podman nor Docker engine is active and available." >&2
    echo "Please ensure Podman or Docker is installed and running." >&2
    exit 1
fi

if [ -f "$TARGET_WRAPPER" ] && [ "$REINSTALL" -eq 0 ]; then
    echo "[cv-make-installer] CV Make is already installed at $TARGET_WRAPPER." >&2
    echo "  - To update the container image, run: cv-make --update" >&2
    echo "  - To force a full reinstallation, run: ./install.sh --reinstall" >&2
    exit 0
fi

if [ "$REINSTALL" -eq 1 ]; then
    echo "[cv-make-installer] Executing reinstallation sequence..." >&2
    if [ -f "$TARGET_WRAPPER" ]; then
        "$TARGET_WRAPPER" --uninstall 2>/dev/null || rm -f "$TARGET_WRAPPER"
    fi
fi

echo "[cv-make-installer] Active container runtime detected: $ENGINE" >&2
echo "[cv-make-installer] Pulling container image: $CONTAINER_IMAGE..." >&2

if ! $ENGINE pull "$CONTAINER_IMAGE"; then
    echo "[ERROR] Failed to pull container image $CONTAINER_IMAGE from GHCR." >&2
    exit 1
fi

mkdir -p "$BIN_DIR"

SOURCE_WRAPPER=""
if [ -f "$SCRIPT_DIR/bin/cv-make" ]; then
    SOURCE_WRAPPER="$SCRIPT_DIR/bin/cv-make"
elif [ -f "$SCRIPT_DIR/cv-make" ]; then
    SOURCE_WRAPPER="$SCRIPT_DIR/cv-make"
fi

if [ -n "$SOURCE_WRAPPER" ] && [ -f "$SOURCE_WRAPPER" ]; then
    echo "[cv-make-installer] Installing wrapper executable from local release package..." >&2
    cp "$SOURCE_WRAPPER" "$TARGET_WRAPPER"
else
    echo "[cv-make-installer] Downloading release archive from GitHub Releases ($RELEASE_VERSION)..." >&2
    
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$RELEASE_URL" -o "$TEMP_DIR/cv-make-linux-amd64.tar.gz"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$RELEASE_URL" -O "$TEMP_DIR/cv-make-linux-amd64.tar.gz"
    else
        echo "[ERROR] Neither curl nor wget is available to download release assets." >&2
        exit 1
    fi

    echo "[cv-make-installer] Extracting wrapper executable..." >&2
    tar -xzf "$TEMP_DIR/cv-make-linux-amd64.tar.gz" -C "$TEMP_DIR"

    if [ -f "$TEMP_DIR/bin/cv-make" ]; then
        cp "$TEMP_DIR/bin/cv-make" "$TARGET_WRAPPER"
    elif [ -f "$TEMP_DIR/cv-make" ]; then
        cp "$TEMP_DIR/cv-make" "$TARGET_WRAPPER"
    else
        echo "[ERROR] Could not find cv-make binary in extracted archive." >&2
        exit 1
    fi
fi

chmod +x "$TARGET_WRAPPER"

# Configure user shell profile to include ~/.local/bin in PATH and set CV_MAKE_CONTAINER_IMAGE
if [[ "$SHELL" == *"zsh"* ]]; then
    PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]] || [ -n "$BASH_VERSION" ]; then
    PROFILE="$HOME/.bashrc"
else
    PROFILE="$HOME/.profile"
fi

touch "$PROFILE"
PROFILE_UPDATED=0

# Ensure PATH contains ~/.local/bin
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$PROFILE" 2>/dev/null; then
        echo '' >> "$PROFILE"
        echo '# CV Make Environment' >> "$PROFILE"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
        PROFILE_UPDATED=1
    fi
fi

# Ensure CV_MAKE_CONTAINER_IMAGE is set to ghcr.io/marcinkaim/cv-make:latest
if ! grep -q 'export CV_MAKE_CONTAINER_IMAGE=' "$PROFILE" 2>/dev/null; then
    if ! grep -q '# CV Make Environment' "$PROFILE" 2>/dev/null; then
        echo '' >> "$PROFILE"
        echo '# CV Make Environment' >> "$PROFILE"
    fi
    echo "export CV_MAKE_CONTAINER_IMAGE=\"$CONTAINER_IMAGE\"" >> "$PROFILE"
    PROFILE_UPDATED=1
elif ! grep -Fxq "export CV_MAKE_CONTAINER_IMAGE=\"$CONTAINER_IMAGE\"" "$PROFILE" 2>/dev/null; then
    # Update existing variable entry to ensure it points to the production GHCR image
    sed -i "s|export CV_MAKE_CONTAINER_IMAGE=.*|export CV_MAKE_CONTAINER_IMAGE=\"$CONTAINER_IMAGE\"|" "$PROFILE"
    PROFILE_UPDATED=1
fi

echo "[cv-make-installer] CV Make installed successfully to $TARGET_WRAPPER!" >&2

if [ "$PROFILE_UPDATED" -eq 1 ]; then
    echo "[cv-make-installer] Shell configuration profile ($PROFILE) updated." >&2
    echo "[cv-make-installer] Run 'source $PROFILE' or open a new terminal session to start using 'cv-make'." >&2
else
    echo "[cv-make-installer] You can now run 'cv-make' from your terminal." >&2
fi
