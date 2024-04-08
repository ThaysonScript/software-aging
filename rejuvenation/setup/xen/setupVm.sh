#!/usr/bin/env bash

############################ IMPORTS #############################
source ../../virtualizer_functions/xen_functions.sh
##################################################################

# UTILS
#   ERROR HANDLE
ERROR_HANDLING() {
    local error=$1
    local status=$2

    [[ $status -eq 0 ]] || {
        echo -e "\nERROR: $error\n"
        exit 1
    }
}

# ERROR MESSAGES
readonly turn_vm_off="error when turning off the virtual machine, it may already be turned off!"
readonly delete_vm="unregistering and deleting files from xenDebian"

# CREATE_VIRTUAL_MACHINE
# DESCRIPTION:
#   TURN_VM_OFF:
#     Tries to turn off the virtual machine
#   
#   DELETE_VM:
#     Attempts to unregister the virtual machine and delete all files associated with it
#
#   CREATE_VM:
#    Attempts to create a virtual machine named 'xenDebian' using 'xen-create-image' 
CREATE_VIRTUAL_MACHINE() {
  TURN_VM_OFF
  ERROR_HANDLING "$turn_vm_off" 0

  DELETE_VM
  ERROR_HANDLING "$delete_vm" 0

  CREATE_VM
}

# DISKS_MANAGEMENT
# DESCRIPTION:
#     Removes all disks from the virtual machine
#     Creates disks in the virtual machine from the given quantity and size
#
# DISK RECOMMENDATIONS:
#     disks_quantity=50
#     disks_size=1024
DISKS_MANAGEMENT() {
  REMOVE_DISKS 
  ERROR_HANDLING "ERROR REMOVING DISKS" 0

  CREATE_DISKS 50 100 # temporarily 100MB CHANGE LATER
  ERROR_HANDLING "ERROR CREATING DISKS" 0
}

#COPY_SSH_ID_AND_TEST_VIRTUAL_MACHINE_SERVER  
# DESCRIPTION:
#   ssh-copy-id:
#       have an ssh key already created, then it will be copied with ssh-copy 
#       and a port will be added and in the end your current shell will be connected to the virtual machine
#
#   curl:
#       Checks whether the request to the server was successful
TEST_VIRTUAL_MACHINE_SERVER() {
  sleep 10

  if ! curl http://172.20.100.178:80; then
    echo -e "ERROR: error when trying to start xenDebian's nginx server\n"
  fi
}

# START_VIRTUAL_MACHINE_IN_BACKGROUND
# DESCRIPTION:
#     START_VM:
#         Starts vm in headless mode
START_MACHINE() {
  read -r -p "Do you want to connect the vm? ( y | n ) - Default=n: " choice

  if [[ "$choice" == "y" ]]; then
    START_VM
  fi
}

SETUP_VM() {
  DISKS_MANAGEMENT
  CREATING_DOMU_ROLES
  CREATE_VIRTUAL_MACHINE
  START_MACHINE
  TEST_VIRTUAL_MACHINE_SERVER
}

SETUP_VM
