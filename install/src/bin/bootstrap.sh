#!/usr/bin/env bash

set -eo pipefail

source ../lib/util/git.sh

download_dotfiles() {
    echo 'Temporarily downloading dotfiles'
    github_download_file_to ickc dotfiles master config/zsh/.zshenv ~/.zshenv
    github_download_file_to ickc dotfiles master config/zsh/.zshrc ~/.zshrc
}

download_dotfiles
# shellcheck disable=SC1090
. ~/.zshenv || true
# shellcheck disable=SC1090
. ~/.zshrc || true
# this must be after sourcing dotfiles
source ../state/env.sh
source ../lib/util/helpers.sh
source ../lib/util/ssh.sh
source ../lib/code.sh
source ../lib/mamba.sh
source ../lib/mamba-env.sh
source ../lib/sman.sh
source ../lib/zim.sh

main() {

    print_double_line
    echo 'Installing VSCode CLI'
    code_install
    print_double_line
    echo "Installing mamba to ${MAMBA_ROOT_PREFIX}"
    mamba_install
    print_double_line
    echo 'Installing system environment via mamba'
    mamba_env_install
    print_double_line
    echo 'Installing sman'
    sman_install
    print_double_line
    echo 'Installing zim'
    zim_install

    print_double_line
    echo 'Generating SSH key and login to GitHub'
    ssh_keygen_and_login

    mkdir -p ~/git/source
    cd ~/git/source
    if [[ ! -d ~/git/source/envoy ]]; then
        print_double_line
        echo 'Cloning envoy'
        github_clone_git ickc envoy
    fi
    if [[ ! -d ~/git/source/dotfiles ]]; then
        print_double_line
        echo 'Cloning dotfiles'
        github_clone_git ickc dotfiles
    fi
    cd dotfiles
    print_double_line
    echo 'Installing dotfiles'
    # this will overwrite ~/.zshenv
    make all
    rm -f ~/.zshrc

    print_double_line
    echo 'Installing to ~/.ssh'
    ssh_dir_install
}

main
