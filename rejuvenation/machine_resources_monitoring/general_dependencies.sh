#!/usr/bin/env bash

KERNEL_VERSION=$(uname -r)

source /etc/os-release
DISTRO_ID="$ID"
DISTRO_CODENAME="$VERSION_CODENAME"

OTHER_DEPENDENCIES() {
  apt install iptables -y
}

SYSTEMTAP_COMPILE() {
  apt remove --purge systemtap*; apt autoremove

  # verificar isso
  apt install libboost-all-dev python3-setuptools-y

  echo "deb http://deb.debian.org/debian-debug/ bookworm-debug main" >> /etc/apt/sources.list
  apt update

  apt install coreutils-dbgsym  # get debug errors list

  cd /root || exit
  apt install git gcc g++ build-essential zlib1g-dev elfutils libdw-dev gettext -y
  git clone "git://sourceware.org/git/systemtap.git"
  cd "systemtap" || exit

  # ./configure  python=':' pyexecdir='' python3='/usr/bin/python3' py3execdir='' --prefix=/root/systemtap_compiled
  ./configure  '--with-boost=/usr/include/boost' python=':' pyexecdir='' python3='/usr/bin/python3' py3execdir='${exec_prefix}/lib/python3.11/site-packages' --prefix=/root/systemtap_compiled

  make; make install


  #Copies the kernel symbols to the boot folder for systemtap
  cp /proc/kallsyms /boot/System.map-"$KERNEL_VERSION"

  echo -n "export PATH=$PATH:/root/systemtap" >> /root/.bashrc
}

INSTALL_GENERAL_DEPENDENCIES() {
  reset; apt update; 

  #Download general packages including systemtap
  apt install linux-headers-"$KERNEL_VERSION" linux-image-"$KERNEL_VERSION"-dbg gnupg wget curl sysstat -y || {
    echo -e "\nERROR: Error installing general packages\n"
    exit 1
  }

  SYSTEMTAP_COMPILE

  source /root/.bashrc
}
