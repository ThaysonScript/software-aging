#!/user/bin/env bash

# ############################## IMPORTS #############################
source ../../virtualizer_functions/kvm_functions.sh
# ####################################################################

readonly DISK_PATH="/var/lib/libvirt/images/$VM_NAME.qcow2"
readonly XML_FILE_PATH="/var/lib/libvirt/images/$VM_NAME.xml"
readonly ISO_NAME="debian-12.5.0-amd64-netinst.iso"

ISO_FIND() {
  if find / -name "$ISO_NAME" | grep "$ISO_NAME"; then
    printf "%s" "O arquivo $ISO_NAME foi encontrado."
  else
    printf "%s" "O arquivo $ISO_NAME não foi encontrado."
    printf "%s\n" "deseja continuar?"
    read -rp "[s/n]: " escolha
    [[ "$escolha" == "s" ]] || exit 1
  fi

  if [[ $(find /var/lib/libvirt/images -name "$VM_NAME.qcow2") ]]; then
    printf "%s\n" "ja tem uma vm criada"
  else
    printf "%s\n" "nao possui vm criada"

    read -rp "deseja criar uma nova maquina virtual? [s/n]: " escolha

    [[ "$escolha" == "s" ]] && CREATE_VM || printf "%s\n" "Não criando uma nova vm"
  fi
}

CREATE_VM() {
  local memory=2048
  local vcpus=2
  local disk_vm_size=20

  local iso_path
  iso_path=$(find / -name "$ISO_NAME" -printf "%h/%f\n")

  # import vm qcow2 and config vm with iso disk
  virt-install \
    --name "$VM_NAME" \
    --memory "$memory" \
    --vcpus "$vcpus" \
    --controller type=sata \
    --disk "$DISK_PATH",size="$disk_vm_size" \
    --os-variant generic \
    --network bridge=virbr0 \
    --cdrom "$iso_path" \
    --virt-type kvm \
    --vnc

  virsh dumpxml "$VM_NAME" >"$XML_FILE_PATH"
}

# CREATE_VIRTUAL_MACHINE
# DESCRIPTION:
#   TURN_VM_OFF:
#     Tries to turn off the virtual machine
#
#   DELETE_VM:
#     Attempts to unregister the virtual machine and delete all files associated with it
#
#   CREATE_VM:
#     Imports the virtual machine vmDebian.ova
#     Attempts to modify the virtual machine to forward traffic from host port 8080 to virtual machine port 80
CREATE_VIRTUAL_MACHINE() {
  TURN_VM_OFF

  DELETE_VM

  ISO_FIND

  # definindo dominio
  if [[ $(virsh define "$XML_FILE_PATH") ]]; then
    printf "%s\n" "importacao das configs da vm feita!"
    START_VM
    printf "esperando 60 segundos para a vm ligar completamente\n" && sleep 60
  else
    printf "%s\n" "erro ao obter xml configs da vm, ela nao sera ligada, pois nao tera dominio no libvirt"
    virsh list --all

    exit 1
  fi
}

# DISKS_MANAGEMENT
# DESCRIPTION:
#     Removes all disks from the virtual machine
#     Creates disks in the virtual machine from the given quantity and size
#
# PARAMETERS:
#     $1 == create disks
#     $2 == remove disks
#
# DISC RECOMMENDATIONS:
#     disks_quantity=50
#     disks_size=1024
DISKS_MANAGEMENT() {
  REMOVE_DISKS
  # ERROR_HANDLING "ERROR REMOVING DISKS" 0

  CREATE_DISKS 50 10
  # ERROR_HANDLING "ERROR CREATING DISKS" 0
}

# START_VIRTUAL_MACHINE_IN_BACKGROUND
# DESCRIPTION:
#     START_VM:
#         Starts vm in headless mode
START_VIRTUAL_MACHINE_IN_BACKGROUND() {
  read -r -p "Do you want to connect the vm? ( y | n ) - Default=n: " choice

  if [[ "$choice" == "y" ]]; then
    START_VM
  fi
}

# COPY_SSH_ID_AND_TEST_VIRTUAL_MACHINE_SERVER
# DESCRIPTION:
#   ssh-copy-id:
#       have an ssh key already created, then it will be copied with ssh-copy
#       and a port will be added and in the end your current shell will be connected to the virtual machine
#
#   curl:
#       Checks whether the request to the server was successful
TEST_VIRTUAL_MACHINE_SERVER() {
  printf "esperando server nginx ligar\n"

  if ! curl "$GET_HOST_IP":8080; then
    printf "%s\n" "ERROR: error when trying to start $VM_NAME nginx server"
  fi
}

NETWORK_REDIRECT_SETTINGS() {
  bash ./create_network_redirect_settings.sh "$VM_NAME"

  cd ./libvirt-hook-qemu || exit 1

  printf "\n%s\n" "-----------------removendo configs de rede-----------------"
  make uninstall
  printf "\n%s\n" "-----------------------------------------------------------"

  printf "\n%s\n" "-----------------adicionando configs de rede-----------------"
  make install
  printf "\n%s\n" "-------------------------------------------------------------"

  systemctl restart libvirtd

  sleep 3

  cd ..
}

CONFIG_QEMU_DOT_CONF() {
  cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.backup.old
  cat ./qemu.conf > /etc/libvirt/qemu.conf
}


SETUP_VM() {
  DISKS_MANAGEMENT
  CREATE_VIRTUAL_MACHINE  # verificar se maquina liga completamente antes de passar para baixo

  NETWORK_REDIRECT_SETTINGS

  TEST_VIRTUAL_MACHINE_SERVER

  CONFIG_QEMU_DOT_CONF
}

SETUP_VM
