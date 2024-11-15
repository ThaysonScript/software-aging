#!/usr/bin/env bash

KERNEL_VERSION=$(uname -r)

source /etc/os-release
DISTRO_ID="$ID"
DISTRO_CODENAME="$VERSION_CODENAME"

SYSTEMTAP_COMPILE() {
  apt remove --purge systemtap*; apt autoremove

  cd /root || exit
  apt install git gcc g++ build-essential zlib1g-dev elfutils libdw-dev gettext -y
  git clone "git://sourceware.org/git/systemtap.git"
  cd "systemtap" || exit
  
  echo "deb http://deb.debian.org/debian-debug/ bookworm-debug main" >> /etc/apt/sources.list
  apt update

  apt install coreutils-dbgsym  # get debug errors list

  ./configure  python=':' pyexecdir='' python3='/usr/bin/python3' py3execdir='' --prefix=/root/systemtap-*
  ./configure  '--disable-option-checking' '--prefix=/usr/local' 'python=:' 'pyexecdir=' 'python3=/usr/bin/python3' 'py3execdir=' '--cache-file=/dev/null' '--srcdir=.' python=':' pyexecdir='' python3='/usr/bin/python3' py3execdir='' --prefix=/root/systemtap-*

  make; make install

  #Copies the kernel symbols to the boot folder for systemtap
  cp /proc/kallsyms /boot/System.map-"$KERNEL_VERSION"

  echo -n 'export SYSTEMTAP="/root/systemtap"' >> /root/.bashrc
  echo -n "export PATH=$PATH:/$SYSTEMTAP" >> /root/.bashrc
}

INSTALL_GENERAL_DEPENDENCIES() {
  reset; apt update
  SYSTEMTAP_COMPILE

  #Download general packages including systemtap
  apt install linux-headers-"$KERNEL_VERSION" linux-image-"$KERNEL_VERSION"-dbg gnupg wget curl sysstat -y || {
    echo -e "\nERROR: Error installing general packages\n"
    exit 1
  }

  source /root/.bashrc
}
