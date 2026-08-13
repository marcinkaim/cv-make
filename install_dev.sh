#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2026 Marcin Kaim
# SPDX-License-Identifier: Apache-2.0
#
# CV Make - install_dev.sh
# Developer installer for local repository environments.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
TARGET_WRAPPER="$BIN_DIR/cv-make"
SOURCE_WRAPPER="$SCRIPT_DIR/bin/cv-make"
DOCKERFILE_PATH="$SCRIPT_DIR/Dockerfile"
IMAGE_NAME="cv-make:dev"

detect_engine() {
    if command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
        echo "podman"
    elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        echo "docker"
    else
        echo ""
    fi
}

ENGINE=$(detect_engine)

show_help() {
    echo "CV Make Developer Repository Installer"
    echo "Usage:"
    echo "  ./install_dev.sh                Install CV Make for local development"
    echo "  ./install_dev.sh --reinstall    Force reinstall/rebuild CV Make dev image"
    echo "  ./install_dev.sh --help         Show this help message"
}

REINSTALL=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --reinstall|--repair)
            REINSTALL=1
            shift
            ;;
        *)
            echo "[ERROR] Unknown option $1" >&2
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$ENGINE" ]; then
    echo "[ERROR] No active container engine detected!" >&2
    echo "cv-make requires a functional Podman or Docker environment." >&2
    exit 1
fi

if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "[ERROR] Dockerfile not found at $DOCKERFILE_PATH!" >&2
    echo "install_dev.sh must be executed from within the CV Make repository root." >&2
    exit 1
fi

if [ ! -f "$SOURCE_WRAPPER" ]; then
    echo "[ERROR] Source wrapper file not found at $SOURCE_WRAPPER!" >&2
    exit 1
fi

# Check if wrapper is already installed
if [ -f "$TARGET_WRAPPER" ] && [ "$REINSTALL" -eq 0 ]; then
    echo "[INFO] CV Make is already installed at: $TARGET_WRAPPER" >&2
    echo "  - To force a full reinstallation/rebuild, run: ./install_dev.sh --reinstall" >&2
    echo "  - To re-build the dev image directly, run: $ENGINE build -t $IMAGE_NAME ." >&2
    exit 0
fi

if [ "$REINSTALL" -eq 1 ]; then
    echo "[cv-make-dev-installer] Executing reinstallation sequence..." >&2
    if [ -f "$TARGET_WRAPPER" ]; then
        "$TARGET_WRAPPER" --uninstall || rm -f "$TARGET_WRAPPER"
    fi
fi

echo "[cv-make-dev-installer] Active container engine detected: $ENGINE" >&2
echo "[cv-make-dev-installer] Building development container image '$IMAGE_NAME'..." >&2

if ! $ENGINE build -t "$IMAGE_NAME" "$SCRIPT_DIR"; then
    echo "[ERROR] Failed to build development container image '$IMAGE_NAME'." >&2
    exit 1
fi

mkdir -p "$BIN_DIR"
echo "[cv-make-dev-installer] Installing static wrapper executable to $TARGET_WRAPPER..." >&2
cp "$SOURCE_WRAPPER" "$TARGET_WRAPPER"
chmod +x "$TARGET_WRAPPER"

configure_shell_profile() {
    local PROFILE=""
    if [ -n "$ZSH_VERSION" ] || [[ "$SHELL" == *"zsh"* ]]; then
        PROFILE="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [[ "$SHELL" == *"bash"* ]]; then
        PROFILE="$HOME/.bashrc"
    else
        PROFILE="$HOME/.profile"
    fi

    touch "$PROFILE"
    local UPDATED=0

    # Ensure PATH contains ~/.local/bin
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$PROFILE" 2>/dev/null; then
            echo '' >> "$PROFILE"
            echo '# CV Make Environment' >> "$PROFILE"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
            UPDATED=1
        fi
    fi

    # Ensure CV_MAKE_CONTAINER_IMAGE is set to cv-make:dev
    if ! grep -q 'export CV_MAKE_CONTAINER_IMAGE=' "$PROFILE" 2>/dev/null; then
        if ! grep -q '# CV Make Environment' "$PROFILE" 2>/dev/null; then
            echo '' >> "$PROFILE"
            echo '# CV Make Environment' >> "$PROFILE"
        fi
        echo 'export CV_MAKE_CONTAINER_IMAGE="cv-make:dev"' >> "$PROFILE"
        UPDATED=1
    fi

    echo "[cv-make-dev-installer] Developer setup complete!" >&2

    if [ "$UPDATED" -eq 1 ]; then
        echo "[cv-make-dev-installer] Shell configuration profile ($PROFILE) updated:" >&2
        echo "  - Added ~/.local/bin to PATH" >&2
        echo "  - Exported CV_MAKE_CONTAINER_IMAGE=\"cv-make:dev\"" >&2
        echo "Please restart your terminal session or execute:" >&2
        echo "  source $PROFILE" >&2
    fi
}

configure_shell_profile
