#!/usr/bin/env bash

######################################## VBOX FUNCTIONS #######################################
# Universidade Federal do Agreste de Pernambuco                                               #
# Uname Research Group                                                                        #
#                                                                                             #
# ABOUT:                                                                                      #
#   utilities for managing virtualbox virtual machines                                    #
###############################################################################################

# ip_host_utils
# source ../utils/networks/get_host_ip.sh

# GLOBAL VARIABLES:
# VM_NAME="vmDebian"
#VM_NAME="debian125"
VM_NAME="debian125-pre-aloc"

# FUNCTION=TURN_VM_OFF()
# DESCRIPTION:
#   Tries to turn off the virtual machine
#
# VBOX COMMANDS:
#    VBoxManage controlvm vmDebian poweroff
TURN_VM_OFF() {
  vboxmanage controlvm "$VM_NAME" poweroff
}

# FUNCTION=DELETE_VM()
# DESCRIPTION:
#   Unregisters the virtual machine and deletes all files associated with it
#
# VBOX COMMANDS:
#   VBoxManage unregistervm vmDebian --delete
DELETE_VM() {
  vboxmanage unregistervm "$VM_NAME" --delete
}

# FUNCTION=GRACEFUL_REBOOT()
# DESCRIPTION:
#   Initiates a graceful reboot using ACPI power button. It has the same effect of pressing the power button on a physical computer
#
# VBOX COMMANDS:
#   VBoxManage controlvm "$VM_NAME" acpipowerbutton
GRACEFUL_REBOOT() {
  vboxmanage controlvm "$VM_NAME" acpipowerbutton
  until vboxmanage startvm "$VM_NAME" --type headless; do
    sleep 1
    echo "Waiting for machine to shutdown"
  done
}

# FUNCTION=FORCED_REBOOT()
# DESCRIPTION:
#   Initiates a forced reboot
#
# VBOX COMMANDS:
#   VBoxManage controlvm "$VM_NAME" reset
FORCED_REBOOT() {
  vboxmanage controlvm "$VM_NAME" reset
}

SSH_REBOOT() {
  ssh -p 2222 root@localhost "/sbin/shutdown -r now"
}

# FUNCTION=CREATE_VM()
# DESCRIPTION:
#   Imports the virtual machine vmDebian.ova
#   Attempts to modify the virtual machine to forward traffic from host port 8080 to virtual machine port 80
#
# VBOX COMMANDS:
#   VBoxManage import vmDebian.ova
#   VBoxManage modifyvm vmDebian --natpf1 "porta 8080,tcp,$host_ip,8080,,80"
CREATE_VM() {
  local host_ip
  host_ip=$(hostname -I | awk '{print $1}')

  vboxmanage import "$VM_NAME".ova
  vboxmanage modifyvm "$VM_NAME" --natpf1 "porta 8080,tcp,$host_ip,8080,,80"
}

# FUNCTION=CREATE_DISKS()
# DESCRIPTION:
#   Creates disks in the virtual machine from the given quantity and size
#
# PARAMETERS:
#   $1 = disks_quantity
#   $2 = disk_size
#
# VBOX COMMANDS:
#   VBoxManage createmedium disk
#
# USAGE:
#   In the main script (run.sh):
#     source ./vbox_functions.sh
#     CREATE_DISKS disks_quantity disk_size
#
# RECOMMENDATIONS:
#   $disks_quantity = 50
#   $disk_size = 1024
CREATE_DISKS() {
  local count=1
  local disks_quantity=$1 # amount of disks to be created
  local disk_size=$2      # size in MB for each disk

  mkdir -p disks

  while [[ "$count" -le "$disks_quantity" ]]; do
    vboxmanage createmedium disk --filename ./disks/disk$count.vhd --size "$disk_size" --format VHD --variant Fixed
    ((count++))
  done
}

# FUNCTION=REMOVE_DISKS()
# DESCRIPTION:
#   Attempts to remove all disks from virtual machine
#
# VBOX COMMANDS:
#   VBoxManage list hdds
#   VBoxManage closemedium disk
REMOVE_DISKS() {
  local uuids_disks
  uuids_disks=$(VBoxManage list hdds | awk '/UUID:/ && !/Parent UUID:/ {print $2}') # get 'UUID' with 'id' and remove 'Parent UUID'

  for uuid_disk in $uuids_disks; do
    echo -e "\n--->> Deleting disk with id: $uuid_disk \n"
    deleting_disk="$(VBoxManage closemedium disk "$uuid_disk" --delete 2>&1)"

    if [[ "$deleting_disk" == *"error:"* ]]; then
      echo -e "Error: Failed to delete medium with UUID: $uuid_disk \n"
      echo -e "***\nDetails: \n$deleting_disk \n***"
    else
      echo "Medium with UUID = $uuid_disk (deleted successfully)"
    fi
  done
}

# FUNCTION=START_VM()
# DESCRIPTION:
#   Attempts to start the vm in the background
#
# GLOBAL VARIABLES:
#   $VM_NAME
#
# VBOX COMMANDS:
#   VBoxManage list runningvms | grep -q "vmDebian"
#   VBoxManage startvm "$VM_NAME" --type headless
START_VM() {
  if VBoxManage list runningvms | grep -q "vmDebian"; then
    echo -e "WARNING: the vm is already running.\n"
  else
    VBoxManage startvm "$VM_NAME" --type headless
  fi
}

# FUNCTION=ATTACH_DISK()
# DESCRIPTION:
#   Attaches disks to virtual machine
#
# GLOBAL VARIABLES:
#   $VM_NAME
#
# PARAMETERS:
#   $1 = disk_path
#
# VBOX COMMANDS:
#   VBoxManage storageattach ... --medium "$disk_path"
#
# USAGE:
#   In the workload script for vbox (vbox_workload.sh):
#       source ./virtualizer_functions/vbox_functions.sh
#       ATTACH_DISK "${disk_path}${count_disks}.vhd" "$port"
ATTACH_DISK() {
  local disk_path="$1"
  local port="$2"
  VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --device 0 --port "$port" --type hdd --medium "$disk_path"
}

# FUNCTION=DETACH_DISK()
# DESCRIPTION:
#   Dettaches disks to virtual machine
#
# GLOBAL VARIABLES:
#   $VM_NAME
#
# VBOX COMMANDS:
#   VBoxManage storageattach ... --medium none
DETACH_DISK() {
  local port="$1"
  VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --device 0 --port "$port" --type hdd --medium none
}

# EXPERIMENTALL FUNCTION
CLONE_DISK() {
  rm -r /root/VirtualBox\ VMs/$VM_NAME/$VM_NAME-disk002*

  # - clonar disco vmdk:
	VBoxManage clonemedium "/root/VirtualBox\ VMs/$VM_NAME/$VM_NAME-disk001.vmdk" "/root/VirtualBox\ VMs/$VM_NAME/$VM_NAME-disk002.vmdk" --format VMDK --variant Fixed

# - remover disco dinâmico da vm e anexar o fixo:
	VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --medium none
	VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "/root/VirtualBox\ VMs/$VM_NAME/$VM_NAME-disk002.vmdk"

# - apagar o disco dinâmico:
	rm -r "/root/VirtualBox\ VMs/$VM_NAME/$VM_NAME-disk001.vmdk"
}