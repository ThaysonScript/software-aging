#!/usr/bin/env bash

# ############################## IMPORTS #############################
source ../../virtualizer_functions/LxcManager.sh
# ####################################################################

readonly VM_NAME="vmDebian"
ISO_PATH="/software-aging/debian-12.5.0-arm64-netinst.iso"
STORAGE_POOL="default"

# FUNCTION=CREATE_VM()
# DESCRIPTION:
# Limits.cpu and limits.memory - configure cpu and memory limit
# Disk source - adds and installation disk to the VM
CREATE_VM() {
  if lxc list | grep -q "$VM_NAME"; then
    echo "$VM_NAME já existe. Parando a função."
    return
  fi

  # Check if the storage pool exists
  if ! lxc storage list | grep -q "$STORAGE_POOL"; then
    echo "Storage pool '$STORAGE_POOL' não encontrado. Criando..."
    lxc storage create "$STORAGE_POOL" dir
  fi

  # Create VM and configure
  lxc init "$VM_NAME" --empty --vm --profile default -s "$STORAGE_POOL"
  lxc config device add "$VM_NAME" root disk pool="$STORAGE_POOL" path=/
  lxc config device add "$VM_NAME" iso disk source="$ISO_PATH" boot.priority=10
  lxc config set "$VM_NAME" limits.cpu=2 limits.memory=512MB

  lxc start "$VM_NAME"
  echo "$VM_NAME iniciada com a ISO $ISO_PATH"
}

START_VM() {
  lxc start "$VM_NAME"
}

STOP_VM() {
  lxc stop "$VM_NAME"
}

DELETE_VM() {
  lxc delete "$VM_NAME" --force
}

RESTART_VM() {
  STOP_VM
  sleep 5
  START_VM
}

SETUP_LXC_VM() {
  CREATE_VM
  START_VM
}

SETUP_LXC_VM