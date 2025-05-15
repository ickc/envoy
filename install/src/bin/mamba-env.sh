#!/usr/bin/env bash

set -euo pipefail

source ../lib/mamba-env.sh

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
