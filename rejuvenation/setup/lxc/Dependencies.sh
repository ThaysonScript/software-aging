#!/usr/bin/env bash

# ############################## IMPORTS #############################
source ../../machine_resources_monitoring/general_dependencies.sh
# ####################################################################

# SYSTEM_UPDATE()
# DESCRIPTION:
# Attempts to update the host's repositories and system apps
SYSTEM_UPDATE() {
  sudo apt-get update && sudo apt-get upgrade -y
} 

INSTALL_UTILS() {
  echo "Instalando utilitários necessários: lxc-templates e bridge-utils..."
  if sudo apt-get install lxc-templates bridge-utils -y; then
    echo "Utilitários instalados com sucesso."
  else
    echo "Erro ao instalar utilitários." >&2
    exit 1
  fi
}

# LXC_INSTALL()
# DESCRIPTION:
# Install LXC if it's not installed
LXC_INSTALL() {
  if ! dpkg -l lxc | grep -q '^ii'; then
    echo "LXC não está instalado, instalando..."
    if ! sudo apt-get install lxc lxd lxd-client -y; then
      echo -e "\nERRO: Erro ao tentar instalar o LXC/LXD\n" >&2
      exit 1
    fi
    echo -e "\nLXC/LXD instalado com sucesso, inicializando LXD...\n"
    INITIALIZE_LXD
  else
    echo "LXC/LXD já está instalado, verificando configuração..."
    INITIALIZE_LXD
  fi
}

# INITIALIZE_LXD()
# DESCRIPTION:
# Initialize LXD with a default storage pool and network
INITIALIZE_LXD() {
  # Check if a default storage pool exists
  if ! sudo lxc storage list | grep -q "default"; then
    sudo lxc storage create default dir
  fi

  # Check if a default NAT network exists
  if ! sudo lxc network list | grep -q "lxdbr0"; then
    sudo lxc network create lxdbr0 ipv4.address=auto ipv4.nat=true ipv6.address=none ipv6.nat=false
  fi

  echo "LXD configurado com storage pool padrão e rede NAT."
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
    SYSTEM_UPDATE
    INSTALL_GENERAL_DEPENDENCIES
    LXC_INSTALL
    echo -e "\nInstalações completas\n"
  else
    echo "ERRO: Este script é apenas para Debian."
    exit 1
  fi
}

INSTALL_DEPENDENCIES