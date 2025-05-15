#!/usr/bin/env bash

set -eo pipefail

__OPT_ROOT="${__OPT_ROOT:-"${HOME}/.local"}"
MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-"${HOME}/.miniforge3"}"
# https://unix.stackexchange.com/a/84980/192799
DOWNLOADDIR="$(mktemp -d 2> /dev/null || mktemp -d -t 'miniforge3')"

# shellcheck disable=SC2312
read -r __OSTYPE __ARCH <<< "$(uname -sm)"

mamba_install() {
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
    cd "${DOWNLOADDIR}" || exit 1
    curl -L "${downloadUrl}" -o Miniforge3.sh
    chmod +x Miniforge3.sh

    print_double_line
    if [[ -f "${MAMBA_ROOT_PREFIX}/etc/profile.d/conda.sh" ]]; then
        echo Updating mamba...
        ./Miniforge3.sh -ubsp "${MAMBA_ROOT_PREFIX}"
    else
        echo Installing mamba...
        ./Miniforge3.sh -fbsp "${MAMBA_ROOT_PREFIX}"
    fi

    print_line
    echo Removing temp dir "${DOWNLOADDIR}"
    rm -rf "${DOWNLOADDIR}"
}

mamba_uninstall() {
    rm -rf "${MAMBA_ROOT_PREFIX}"
}
# git 2.3.0 or later is required
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

github_clone_git() {
    user="$1"
    repo="$2"
    git clone "git@github.com:${user}/${repo}.git"
}

github_clone_https() {
    user="$1"
    repo="$2"
    git clone "https://github.com/${user}/${repo}.git"
}

github_download_file_to() {
    user="$1"
    repo="$2"
    branch="$3"
    file="$4"
    dest="$5"
    curl -L "https://raw.githubusercontent.com/${user}/${repo}/refs/heads/${branch}/${file}" -o "${dest}"
}
print_double_line() {
    eval printf %.0s= '{1..'"${COLUMNS:-80}"\}
}

print_line() {
    eval printf %.0s- '{1..'"${COLUMNS:-80}"\}
}
BSOS_SSH_COMMENT="${USER}@${HOSTNAME}"

ssh_keygen_and_login() {
    # determine ssh algorithm to use
    # shellcheck disable=SC2312
    if ssh -Q key | grep -q "ssh-ed25519"; then
        SSH_ALGO=ed25519
    elif ssh -Q key | grep -q "ssh-rsa"; then
        SSH_ALGO=rsa
    else
        echo "No supported ssh algorithm found, abort..."
        return
    fi

    if [[ -f "${HOME}/.ssh/id_${SSH_ALGO}.pub" ]]; then
        echo "SSH key already exists, assuming ssh-agent is setup to pull from GitHub and skip generating ssh key."
    else
        echo "Generating ssh key for ${BSOS_SSH_COMMENT}"
        mkdir -p "${HOME}/.ssh"
        ssh-keygen -t "${SSH_ALGO}" -C "${BSOS_SSH_COMMENT}" -f "${HOME}/.ssh/id_${SSH_ALGO}"
        # shellcheck disable=SC1090,SC2312
        . <(ssh-agent -s)
        ssh-add "${HOME}/.ssh/id_${SSH_ALGO}"

        # authenticate with GitHub
        gh auth login --git-protocol ssh --web
    fi
}

ssh_dir_install() {
    cd ~
    github_clone_git ickc ssh-dir
    cd ssh-dir
    mv ~/.ssh/id_ed25519 ~/ssh-dir
    mv ~/.ssh/id_ed25519.pub ~/ssh-dir
    rm -rf ~/.ssh
    mv ~/ssh-dir ~/.ssh
}

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
