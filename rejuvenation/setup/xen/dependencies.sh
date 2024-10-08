#!/usr/bin/env bash

# REFERENCES:
# https://wiki.xenproject.org/wiki/Xen_Project_Beginners_Guide
# https://xen-tools.org/software/xen-tools/
# https://wiki.debian.org/LVM#List_of_VG_commands

# ############################## IMPORTS #############################
source ../../machine_resources_monitoring/general_dependencies.sh
source ../../virtualizer_functions/xen_functions.sh
# ####################################################################

# FUNCTION=SYSTEM_UPDATE()
# DESCRIPTION:
# Attempts to update the host's repositories and system apps
SYSTEM_UPDATE() {
  apt-get update && apt-get upgrade
} 

# FUNCTION=INSTALL_XEN_AND_DEPENDENCIES()
# DESCRIPTION:
# Installs Xen dependencies if not already installed
INSTALL_XEN_DEPENDENCIES() {
  if ! which xen-system >/dev/null; then
    apt-get install xen-system -y
  fi
}

# FUNCTION=INSTALL_UTILS()
# DESCRIPTION:
# Installs recommended tools for the setup of the Xen hypervisor in a Debian host
#
# xen-tools: This package will allow the creation of new guest Xen domains on a Debian host
# lvm2: Allows the management of storage devices in a more abstract manner using LVM or 'Linux Logical Volume Manager'
# net-tools: Includes the important tools for controlling the Linux kernel's networking subsystem
# bridge-utils: Acts as a virtual switch, enabling the attachment of VMs to the external network
# iptables: useful for port redirecting dom0's 2222 -> domU's 22 and dom0's 8080 -> domU's 80
INSTALL_UTILS(){
  apt install xen-tools lvm2 net-tools bridge-utils iptables 
}

# FUNCTION=CONFIGURE_GRUB_FOR_XEN()
# DESCRIPTION:
# Configures GRUB to set up boot priority for Xen, modifying the default Linux GRUB script
# Ensures that Xen is initialized along with the system and that it has access to the hardware components
CONFIGURE_GRUB_FOR_XEN(){
  dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
  update-grub
}

# FUNCTION=NETWORK_CONFIG()
# DESCRIPTION:
# Creates a bridge interface (xenbr0) in the dom0, connects it to the default network interface of the host by altering the '/etc/network/interfaces' file
NETWORK_CONFIG(){
    if [ -z "$default_interface" ]; then
        echo "Error: No proper network interface found."
        exit 1
    fi

    echo "Updating network configuration file..."
    cat > "$config_file" <<EOL
# This file describes the network interfaces available on your system 
# and how to activate them. For more information, see interfaces (5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug $default_interface
iface $default_interface inet manual

auto $LAN_INTERFACE
iface $LAN_INTERFACE inet dhcp 
    bridge_ports $default_interface
EOL

  service networking restart
}

# FUNCTION=STORAGE_SETUP()
# DESCRIPTION:
#   Configures /dev/sda4 to be the physical volume of LVM or 'Linux Logical Volume Manager' in order to 
#   set up foundation for creating disks for future VMs
# 
# Useful definitions:
#   PV - Physical Volumes. This means the hard disk, hard disk partitions, RAID or LUNs from a SAN which form "Physical Volumes" (or PVs)
#   VG - Volume Groups. This is a collection of one or more Physical Volumes
#   LV - Logical Volumes. LVs sit inside a Volume Group and form, in effect, a virtual partition
#
# LVM COMMANDS:
#   pvcreate - declares /dev/sda4 ( /dev/nvme0n1p4 ) as a physical volume available for the LVM
#   vgcreate - creates a volume group called 'vg0'
#
# REMINDER: Before using this function, ensure that /dev/sda4 ( /dev/nvme0n1p4 ) is a dedicated partition you created for LVM use
STORAGE_SETUP() { 
    printf "%s\n\n" "---------------- LS PARTITIONS --------------------"
    lsblk --list
    printf "\n%s\n\n" "---------------------------------------------------"
    sleep 3

    printf "%s\n" "------------- LVM CONFIGURATION -----------------"
    printf "%s\n" "WHICH LVM PARTITION?"
    printf "%s\n" "SET EXAMPLE: /dev/sda4"

    read -p "SET PARTITION: " get_partition
    sleep 2
    printf "%s\n" "PARTITION CHOSEN: $get_partition"
    printf "%s\n" "--------------------------------------------------"

    pvcreate $get_partition 
    vgcreate vg0 $get_partition
}

DEPENDENCIES_MAIN(){
  SYSTEM_UPDATE
  INSTALL_GENERAL_DEPENDENCIES
  INSTALL_XEN_DEPENDENCIES
  INSTALL_UTILS
  CONFIGURE_GRUB_FOR_XEN
  NETWORK_CONFIG
  REDIRECT_PORTS
  STORAGE_SETUP

  printf "%s\n" "REBOOTING MACHINE?"
  printf "%s\n" "[ 1 ] - REBOOTING"
  printf "%s\n" "[ 2 ] - NOT REBOOTING"

  read -p "number: " number
  if [[ "$number" -eq 1 ]]; then
    echo "REBOOTING..."; sleep 3
    shutdown -r now
  else
    printf "%s\n" "---> EXECUTING redirectPort.sh FOR REDIRECT PORTS"
    echo "NOT REBOOTING..."; sleep 3
  fi
}

DEPENDENCIES_MAIN

