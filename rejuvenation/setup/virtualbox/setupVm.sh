#!/usr/bin/env bash

# ############## IMPORTS ############### 
# shellcheck disable=SC1091
source ../../virtualizer_functions/vbox_functions.sh
source ../../utils/messages.sh
source ../../utils/errors.sh
# ######################################

# CHECK_DEBIAN_IMAGE
# DESCRIPTION:
#   Checks if the virtual machine file vmDebian.ova is in a folder before the rejuvenation folder
CHECK_DEBIAN_IMAGE() {
  read -r -p "Have you copied the VM vmDebian.ova file? It should have been put inside the setup folder (y/n): " copy

  if [ "$copy" != "y" ]; then
    echo -e "right, copy the debian system image to the location provided!\n"
    exit 1
  fi
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
  CHECK_DEBIAN_IMAGE

  TURN_VM_OFF
  ERROR_HANDLING "$POWEROFF" 0

  DELETE_VM
  ERROR_HANDLING "$UNREGISTER" 0

  CREATE_VM
  ERROR_HANDLING "$IMPORT_MODIFY" 0
  cd .. || exit
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
  ERROR_HANDLING "ERROR REMOVING DISKS" 0

  CREATE_DISKS 50 100
  ERROR_HANDLING "ERROR CREATING DISKS" 0
}

# START_VIRTUAL_MACHINE_IN_BACKGROUND
# DESCRIPTION:
#     START_VM:
#         Starts vm in headless mode
START_VIRTUAL_MACHINE_IN_BACKGROUND() {
  read -r -p "Do you want to connect the vm? ( y | n ) - Default=n: \n" choice

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
  sleep 10
  # curl "$GET_HOST_IP:8080"
  
  if ! curl "$(hostname -I | awk '{print $1}')":8080; then
    echo -e "ERROR: error when trying to start vmDebian's nginx server\n"
  fi
}

SETUP_VM() {
  DISKS_MANAGEMENT
  CREATE_VIRTUAL_MACHINE
  START_VM
  TEST_VIRTUAL_MACHINE_SERVER
}

SETUP_VM
