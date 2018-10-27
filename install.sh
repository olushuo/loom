#!/bin/bash

source $(dirname ${BASH_SOURCE})/trace.sh || die "Failed to find trace.sh"

declare -x ALL="no"
declare -x GOVERSION="1.10.2"
declare -x JAVAVERSION="1.8.0_172"

function usage() {
    echo "${0##*/} usage:"
    echo "  -h : Print help message"
    echo "  -a : Install everything by default"
}

if [[ $# > 1 ]] ; then
    usage
    exit 1
elif [[ $# == 1 && $1 == "-h" ]] ; then
    usage
    exit 0
elif [[ $# == 1 && $1 == "-a" ]] ; then
    echo "=============================================================="
    warn "Everything will be installed"
    echo "=============================================================="
    ALL="yes"
fi

 "Loom is going to be installed..."

confirmCont "So far, Loom is only tested on Ubuntu 1604/1804, are your sure you want to continue?" YES no

if [ ${ALL} = "yes" ] || confirm "Vim and Git is needed" y n y ; then
    sudo apt install -y vim git
else
    die "Aborted installation, since Vim and Git is aboslutely necessary!" 
fi

info "Installing Vundle..."
if [ -d "${HOME}/.vim/bundle/Vundle.vim" ] ; then
    cd ~/.vim/bundle/Vundle.vim
    info "Updating Vundle.vim..."
    git pull
    cd - >> /dev/null
else
    info "Installing Vundle.vim..."
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
cp -v ./vimrc_ubuntu1804 ~/.vimrc

info "Installing all plugins..." 
vim +PluginInstall +qall

info "Installing build-essential cmake python3-dev..." 
sudo apt install -y build-essential cmake python3-dev

if confirm "Enable C famaily language support..." y n y; then
    sudo apt install -y exuberant-ctags cscope gdb g++ make 
fi

if [ ${ALL} == "yes" ] || confirm "Enable CSharp support..." y n y; then
    info "Installing Mono..." 
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
        --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" \
        | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
    sudo apt update

    sudo apt install -y mono-complete
fi

if confirm "Enable Go support" y n y; then
    info "Installing Go..."
    bash $(dirname ${BASH_SOURCE})/go_install.sh ${GOVERSION}
fi

if [ ${ALL} == "yes" ] || confirm "Enable JavaScript support" y n y; then
    wget -qO- https://deb.nodesource.com/setup_10.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo npm install -g typescript
fi

if [ ${ALL} == "yes" ] || confirm "Enable Rust support" y n y; then
    curl https://sh.rustup.rs -sSf | sh
fi

if [ ${ALL} == "yes" ] || confirm "Enable Java support" y n y ; then
    info "Installing JDK..."
fi
exit
info "Set up tern_for_vim..."
cd ~/.vim/bundle/tern_for_vim
npm install

info "Set up fonts..."
cd ~/.vim/bundle/fonts
./install.sh

info "Installing cargo and some extra package..."
sudo apt install -y cargo cargo-doc gdb-doc rust-doc rust-src \
    libhttp-parser2.7.1 libstd-rust-1.28 libstd-rust-dev \
    rust-gdb rustc rust-gdb rustc ack

info "Compiling YouCompleteMe, it may take a while..."
cd ~/.vim/bundle/YouCompleteMe
if [ ${ALL} == yes ] ; then
    python3 install.py --all
else
    python3 install.py ${CSharpSupport} ${CFamilySupport} ${GoSupport}
fi

info "Return to your home directory..."
cd ~


