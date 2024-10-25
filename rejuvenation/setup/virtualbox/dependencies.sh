#!/usr/bin/env bash

# ############################## IMPORTS #############################
source ../../machine_resources_monitoring/general_dependencies.sh
# ####################################################################

#Download and install virtualbox if it's not installed
VIRTUALBOX_INSTALL() {
  if which vboxmanage; then
    echo "Skipping virtualbox addition as it's already configured."
  else
    cp /etc/apt/sources.list /etc/apt/sources.list.backup

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $DISTRO_CODENAME contrib" >>/etc/apt/sources.list

    wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg

    apt update
    if ! apt install virtualbox-7.0 -y; then
      echo -e "\nVirtualBox installed successfully\n"
    else
      echo -e "\nERROR: Error when trying to install virtualbox\n" >&2
      exit 1
    fi
  fi
}

# START_DEPENDENCIES
# DESCRIPTION:
#   starts dependency checking and install dependencies requirements
INSTALL_DEPENDENCIES() {
  case $DISTRO_ID in
  "debian" | "ubuntu")
    reset

    INSTALL_GENERAL_DEPENDENCIES
    VIRTUALBOX_INSTALL

    echo -e "\nInstallations Completed\n"
    return 0
    ;;

  *)
    echo "ERROR: error identifying the distribution"
    exit 1
    ;;
  esac
}

INSTALL_DEPENDENCIES

sudo rm /usr/bin/vboxmanage

sudo ln -s /usr/lib/virtualbox/VBoxManage /usr/bin/vboxmanage
