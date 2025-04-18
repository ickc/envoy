#!/usr/bin/env bash

set -e

__CONDA_PREFIX="${__CONDA_PREFIX:-"${HOME}/.miniforge3"}"
# https://unix.stackexchange.com/a/84980/192799
DOWNLOADDIR="$(mktemp -d 2> /dev/null || mktemp -d -t 'miniforge3')"

read -r __OSTYPE __ARCH <<< "$(uname -sm)"

# helpers ##############################################################

print_double_line() {
    eval printf %.0s= '{1..'"${COLUMNS:-80}"\}
}

print_line() {
    eval printf %.0s- '{1..'"${COLUMNS:-80}"\}
}

########################################################################

install() {
    case "${__OSTYPE}-${__ARCH}" in
        Darwin-arm64) ;;
        Darwin-x86_64) ;;
        Linux-x86_64) ;;
        Linux-aarch64) ;;
        Linux-ppc64le) ;;
        *) exit 1 ;;
    esac
    # https://github.com/conda-forge/miniforge
    downloadUrl="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${__OSTYPE}-${__ARCH}.sh"

    print_double_line
    echo Downloading to temp dir "${DOWNLOADDIR}"
    cd "${DOWNLOADDIR}"
    curl -L "${downloadUrl}" -o Miniforge3.sh
    chmod +x Miniforge3.sh

    print_double_line
    if [[ -f "${__CONDA_PREFIX}/etc/profile.d/conda.sh" ]]; then
        echo Updating mamba...
        ./Miniforge3.sh -ubsp "${__CONDA_PREFIX}"
    else
        echo Installing mamba...
        ./Miniforge3.sh -fbsp "${__CONDA_PREFIX}"
    fi

    print_line
    echo Removing temp dir "${DOWNLOADDIR}"
    rm -rf "${DOWNLOADDIR}"
}

uninstall() {
    rm -rf "${__CONDA_PREFIX}"
}

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: __CONDA_PREFIX=... $0 [install|uninstall]"
        exit 1
        ;;
esac
