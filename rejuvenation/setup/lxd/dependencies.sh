#!/usr/bin/env bash

# ############################## IMPORTS #############################
source ../../machine_resources_monitoring/general_dependencies.sh
# ####################################################################

lxd_configure() {
  lxd init
}

install_lxd() {
  apt install lxd lvm2 qemu-system-x86 virt-viewer -y

  lxd_configure
}

# LXD_INSTALL_DEPENDENCIES()
# DESCRIPTION:
# Install LXC if it's not installed
LXD_INSTALL_DEPENDENCIES() {
  install_lxd
}

# INSTALL_DEPENDENCIES()
# DESCRIPTION:
# Starts dependency checking and installs dependencies requirements
INSTALL_DEPENDENCIES() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
  else
    echo "Não foi possível determinar a distribuição do sistema."
    exit 1
  fi

  if [ $ID = "debian" ]; then
    INSTALL_GENERAL_DEPENDENCIES
    LXD_INSTALL_DEPENDENCIES

    echo -e "\nInstalações completas\n"

  else
    echo "ERRO: Este script é apenas para Debian."
    exit 1
    
  fi
}

INSTALL_DEPENDENCIES
