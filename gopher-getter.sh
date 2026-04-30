#!/usr/bin/env bash
#
# Cross-platform Go installer.
# Downloads the latest stable version, verifies SHA256, and installs it.
# Works on Linux and macOS.

set -euo pipefail
IFS=$'\n\t'

######################################
#             Constants              #
######################################
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
GO_INSTALL_DIR="${HOME}/.local"
GO_DL_API="https://go.dev/dl/?mode=json"

DEPENDENCIES="tar,wget,jq,mktemp"

# Normalize architecture names
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64 | arm64) ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Determine SHA256 tool
if command -v sha256sum &>/dev/null; then
    SHA_TOOL="sha256sum"
elif command -v shasum &>/dev/null; then
    SHA_TOOL="shasum -a 256"
else
    echo "No SHA256 checksum tool found (need sha256sum or shasum)."
    exit 2
fi

######################################
#        Dependency Checking         #
######################################
dependency_check() {
    IFS=',' read -ra deps <<< "$DEPENDENCIES"
    for dependency in "${deps[@]}"; do
        if ! command -v "$dependency" &>/dev/null; then
            echo "Dependency '$dependency' not found. Please install it and try again."
            exit 2
        fi
    done
}

######################################
#     Identify Latest Go Version     #
######################################
identify_latest_version() {
    wget -qO- "$GO_DL_API" \
        | jq -r '.[] | select(.stable == true) | .version' \
        | head -n1
}

######################################
#      Download and Install Go       #
######################################
download_and_install() {
    local version="$1"
    local base_url="https://go.dev/dl"
    local archive="${version}.${OS}-${ARCH}.tar.gz"
    local tmp_archive

    tmp_archive="$(mktemp)"

    echo "Downloading Go ${version} archive..."
    wget -qO "$tmp_archive" "${base_url}/${archive}"

    echo "Fetching checksum from JSON API..."
    expected="$(wget -qO- "$GO_DL_API" \
        | jq -r --arg ver "$version" --arg os "$OS" --arg arch "$ARCH" '
            .[] 
            | select(.version == $ver) 
            | .files[] 
            | select(.os == $os and .arch == $arch and .kind == "archive") 
            | .sha256
        ')"

    if [[ -z "$expected" ]]; then
        echo "Failed to get SHA256 checksum for ${version}."
        rm -f "$tmp_archive"
        exit 1
    fi

    echo "Verifying SHA256 checksum..."
    checksum="$($SHA_TOOL "$tmp_archive" | awk '{print $1}')"
    if [[ "$checksum" != "$expected" ]]; then
        echo "Checksum verification failed!"
        echo "Expected: $expected"
        echo "Got:      $checksum"
        rm -f "$tmp_archive"
        exit 1
    fi

    echo "Checksum verified."

    echo "Installing Go ${version}..."
    rm -rf "${GO_INSTALL_DIR}/go"
    tar -C "$GO_INSTALL_DIR" -xzf "$tmp_archive"
    chmod +x "${GO_INSTALL_DIR}/go/bin/"*

    rm -f "$tmp_archive"

    if [[ ":$PATH:" == *":${GO_INSTALL_DIR}/go/bin:"* ]]; then
        echo "Go ${version} installed successfully."
    else
        printf "Go %s installed successfully.\nPlease add '%s/go/bin' to your PATH.\n" \
            "$version" "$GO_INSTALL_DIR"
    fi
}

######################################
#         Check Current Version      #
######################################
check_if_up_to_date() {
    local latest="$1"
    if command -v go &>/dev/null; then
        local current
        current="$(go version | awk '{print $3}')"
        if [[ "$current" == "$latest" ]]; then
            echo "Go is already up to date (${current})."
            exit 0
        else
            echo "Current version: ${current}"
            echo "Latest version:  ${latest}"
        fi
    fi
}

######################################
#               Main                 #
######################################
main() {
    dependency_check

    local latest_version
    latest_version="$(identify_latest_version)" || {
        echo "Failed to determine the latest Go version."
        exit 1
    }

    if [[ -z "$latest_version" ]]; then
        echo "Could not determine latest Go version."
        exit 1
    fi

    check_if_up_to_date "$latest_version"
    download_and_install "$latest_version"
}

main "$@"
