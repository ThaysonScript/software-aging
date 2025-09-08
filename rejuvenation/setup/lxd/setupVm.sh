#!/usr/bin/env bash

# ############################## IMPORTS #############################

# imported
#   vm_name
#   iso_path
#   iso_name
# 
#   all_functions
source ../../virtualizer_functions/lxc_functions.sh
# ####################################################################

# ############################## VM_CONFIG #############################
cpu=2
memory=2
volume_disk_size=5
# ######################################################################

# CONFIG PARTITIONS, POOLS AND VOLUMES
storage_setup

REMOVE_DISKS
CREATE_DISKS 50 1024

# CREATE VM WITH ISO
lxd_empty_vm_configure "$vm_name" "$cpu" "$memory" "$volume_disk_size" "$iso_name" "$iso_path"

