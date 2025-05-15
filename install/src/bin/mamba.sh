#!/usr/bin/env bash

set -euo pipefail

source ../lib/mamba.sh

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: MAMBA_ROOT_PREFIX=... $0 [install|uninstall]"
        exit 1
        ;;
esac
