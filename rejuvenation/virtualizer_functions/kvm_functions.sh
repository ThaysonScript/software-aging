#!/usr/bin/env bash
# usage:
#   $ bash kvm_functions.sh

######################################## KVM FUNCTIONS ########################################
# Universidade Federal do Agreste de Pernambuco                                               #
# Uname Research Group                                                                        #
#                                                                                             #
# ABOUT:                                                                                      #
#   utilities for managing kvm virtual machines                                               #
###############################################################################################

VM_NAME="debian125"

GET_GUEST_IP="$(virsh net-dhcp-leases default | grep "debian" | awk '/ipv4/ {gsub("/24", "", $5); print $5}')"
GET_HOST_IP="$(hostname -I | awk '{print $1}')"

RESTART_LIBVIRTD_SERVICE() {
  systemctl restart libvirtd
}

TURN_VM_OFF() {
  virsh shutdown "$VM_NAME"
  saida=$?

  while [ "$saida" -eq 0 ]; do
    printf "%s\n" "esperando a vm desligar..."
    virsh shutdown "$VM_NAME"
    saida=$?

    sleep 3
  done
}

DELETE_VM() {
  virsh undefine "$VM_NAME"
}

GRACEFUL_REBOOT() {
  RESTART_LIBVIRTD_SERVICE
  
  virsh shutdown "$VM_NAME"

  until virsh start "$VM_NAME"; do
    sleep 1
    echo "Waiting for machine to shutdown"
  done
}

FORCED_REBOOT() {
  RESTART_LIBVIRTD_SERVICE

  virsh reset "$VM_NAME"
}

SSH_REBOOT() {
  ssh -p 2222 root@"$GET_HOST_IP" "systemctl restart libvirtd"

  ssh -p 2222 root@"$GET_HOST_IP" "reboot $VM_NAME"
}

# FUNCTION=CREATE_DISKS()
# USAGE:
#   CREATE_DISKS 3 1G
CREATE_DISKS() {
  local count=1
  local disks_quantity=$1      # amount of disks to be created
  local allocated_disk_size=$2 # size for disk

  mkdir -p ./disks_kvm

  while [[ "$count" -le "$disks_quantity" ]]; do
    qemu-img create -f qcow2 -o preallocation=full ./disks_kvm/disk"$count".qcow2 "$allocated_disk_size"M
    sleep 0.2
    ((count++))
  done
}

REMOVE_DISKS() {
  local disk_files
  disk_files=$(ls ./disks_kvm/*.qcow2) # lista todos os discos no diretório 'disks'

  for disk_file in $disk_files; do
    echo -e "\n--->> Deletando o disco: $disk_file \n"
    rm -f "$disk_file"
    sleep 0.2
    if [[ -f $disk_file ]]; then
      echo -e "Erro: Falha ao deletar o disco: $disk_file \n"
    else
      echo "Disco $disk_file deletado com sucesso"
    fi
  done
}

# FUNCTION=START_VM()
# RUN FOR HELPER:
#   virsh start --help
START_VM() {
  virsh start "$VM_NAME"
}

# FUNCTION=ATTACH_DISK()
# RUN FOR HELPER:
#   virsh attach-disk --help
#
# verifique a anexagem dos discos com virsh domblklist <vmName> ou simplesmente lsblk dentro da vm
ATTACH_DISK() {
  local disk_path="$1"
  local target="$2"

  virsh attach-disk "$VM_NAME" --source "$disk_path" --target "$target" --persistent --config > /dev/null
}

# FUNCTION=DETACH_DISK()
# RUN FOR HELPER:
#   virsh detach-disk --help
#
# verifique a desanexagem dos discos com virsh domblklist <vmName> ou simplesmente lsblk dentro da vm
DETACH_DISK() {
  local target="$1"

  # virsh detach-disk "$VM_NAME" "$disk_path"
  virsh detach-disk "$VM_NAME" "$target" --persistent --config > /dev/null
}

# FUNCTION=TURN_ON_GRAPHICAL_INTERFACE()
# RUN FOR HELPER:
#   virt-viewer --help
TURN_ON_GRAPHICAL_INTERFACE() {
  virt-viewer --connect qemu:///session --wait "$VM_NAME"
}
