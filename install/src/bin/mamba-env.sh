#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/mamba-env.sh
source ../lib/mamba-env.sh

case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: MAMBA_ROOT_PREFIX=... __OPT_ROOT=... NAME=(system|py313|...) $0 [install|uninstall]"
        exit 1
        ;;
esac
