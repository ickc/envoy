#!/usr/bin/env bash

set -eo pipefail

# shellcheck source=../state/env.sh
source ../state/env.sh
# shellcheck source=../lib/mamba.sh
source ../lib/mamba.sh
# shellcheck source=../lib/util/git.sh
source ../lib/util/git.sh
# shellcheck source=../lib/util/helpers.sh
source ../lib/util/helpers.sh
# shellcheck source=../lib/util/ssh.sh
source ../lib/util/ssh.sh

main() {
    # temporary put this file here to setup the env var for install
    github_download_file_to ickc dotfiles master config/zsh/.zshenv ~/.zshenv
    # shellcheck disable=SC1090
    . ~/.zshenv

    code_install
    mamba_install
    mamba_env_install
    sman_install
    zim_install

    ssh_keygen_and_login

    mkdir -p ~/git/source
    cd ~/git/source
    if [[ ! -d ~/git/source/envoy ]]; then
        github_clone_git ickc envoy
    fi
    if [[ ! -d ~/git/source/dotfiles ]]; then
        github_clone_git ickc dotfiles
    fi
    cd dotfiles
    # this will overwrite ~/.zshenv
    make all

    ssh_dir_install
}

main
