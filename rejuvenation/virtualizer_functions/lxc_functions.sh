#!/usr/bin/env bash

######################################## LXC FUNCTIONS ########################################
# Universidade Federal do Agreste de Pernambuco                                               #
# Uname Research Group                                                                        #
#                                                                                             #
# ABOUT:                                                                                      #
# utilities for managing LXC virtual machines                                                 #
###############################################################################################

vm_name="vmDebian"

iso_path='/root/*.iso'
iso_name='iso-volume'

storage_setup() {
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

  pvcreate "$get_partition"
  vgcreate vg0 "$get_partition"

  lxc storage create lvm-pool lvm source=vg0
}

lxd_detach_custom_volume_after_installation() {
  local vm_name=$1
  local iso_name=$2

  lxc config device remove "$vm_name" "$iso_name"
}

lxd_empty_vm_configure() {
  local vm_name=$1
  local cpu=$2
  local memory=$3
  local vm_disk_size=$4

  local iso_name=$5
  local iso_path=$6

  lxc init "$vm_name" --empty --vm --config limits.cpu="$cpu" --config limits.memory="$memory"GiB --device root,size="$vm_disk_size"GiB

  lxc config device add "$vm_name" "$iso_name" disk source="$iso_path" boot.priority=10

  lxd_detach_custom_volume_after_installation "$vm_name" "$iso_name"
}

lxd_start_vm_on_console() {
  lxc start "$vm_name"
  lxc console "$vm_name" --type=vga
}

START_VM() {
  lxc start "$vm_name"
}

STOP_VM() {
  lxc stop "$vm_name"
}

DELETE_VM() {
  lxc delete "$vm_name" --force
}

# FUNCTION=FORCED_REBOOT()
# DESCRIPTION:
#   Forcibly reboot the virtual machine
FORCED_REBOOT() {
  lxc restart "$vm_name"
}

CREATE_DISKS() {
  local count=1
  local disks_quantity=$1      # amount of disks to be created
  local allocated_disk_size=$2 # size for disk

  mkdir -p ./disks_lxc

  while [[ "$count" -le "$disks_quantity" ]]; do
    qemu-img create -f qcow2 -o preallocation=full ./disks_lxc/disk"$count".qcow2 "$allocated_disk_size"M
    sleep 0.2
    ((count++))

  done
}


REMOVE_DISKS() {
  local disk_files
  disk_files=$(ls ./disks_lxc/*.qcow2) # lists all disks in the 'disks' directory

  for disk_file in $disk_files; do
    echo -e "\n--->> Deletando o disco: $disk_file \n"
    rm -rf "$disk_file"
    sleep 0.2
    
    if [[ -f $disk_file ]]; then
      echo -e "Erro: Falha ao deletar o disco: $disk_file \n"
    
    else
      echo "Disco $disk_file deletado com sucesso"
    fi
  done
}

# FUNCTION=ATTACH_DISK()
# DESCRIPTION:
# Attaches disks to virtual machine
#
# PARAMETERS:
# disk_path = $1
# target = $2
ATTACH_DISK() {
  local disk_name_attach=$1
  local disk_path_attach=$2
  local disk_target_folder=$3

  if lxc config device add "$vm_name" "$disk_name_attach" disk source="$disk_path_attach" path="$disk_target_folder"; then
    echo "Disco anexado com sucesso ao alvo $disk_target_folder."

  else
    echo "ERRO: Falha ao anexar o disco ao alvo $disk_target_folder."

  fi
}

# FUNCTION=DETACH_DISK()
# DESCRIPTION:
#   Detach disks to virtual machine
#
# PARAMETERS:
#   target = $1  #Name of the device to detach
DETACH_DISK() {
  local disk_name_dettach=$1

  if lxc config device remove "$vm_name" "$disk_name_dettach"; then
    echo "Disco desanexado com sucesso do dispositivo $disk_name_dettach."

  else
    echo "ERRO: Falha ao desanexar o disco do dispositivo $disk_name_dettach."

  fi
}
