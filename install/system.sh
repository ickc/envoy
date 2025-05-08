#!/usr/bin/env bash

set -e

__CONDA_PREFIX="${__CONDA_PREFIX:-"${HOME}/.miniforge3"}"
__OPT_ROOT="${__OPT_ROOT:-${HOME}/.local}"
NAME="${NAME:-system}"

PREFIX="${__OPT_ROOT}/${NAME}"

read -r __OSTYPE __ARCH <<< "$(uname -sm)"

install() {
    case "${__OSTYPE}-${__ARCH}" in
        Darwin-arm64) CONDA_UNAME=osx-arm64 ;;
        Darwin-x86_64) CONDA_UNAME=osx-64 ;;
        Linux-x86_64) CONDA_UNAME=linux-64 ;;
        Linux-aarch64) CONDA_UNAME=linux-aarch64 ;;
        Linux-ppc64le) CONDA_UNAME=linux-ppc64le ;;
        *) exit 1 ;;
    esac
    file="conda/${NAME}_${CONDA_UNAME}.yml"

    if [[ -d ${PREFIX} ]]; then
        mamba env update -f "${file}" -p "${PREFIX}" --prune
    else
        mamba env create -f "${file}" -p "${PREFIX}"
    fi
}

uninstall() {
    rm -rf "${PREFIX}"
}

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: __CONDA_PREFIX=... __OPT_ROOT=... NAME=(system|py313|...) $0 [install|uninstall]"
        exit 1
        ;;
esac
