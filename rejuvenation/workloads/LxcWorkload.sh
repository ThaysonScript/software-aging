#!/usr/bin/env bash

######################################## LXC - WORKLOAD #######################################
# ABOUT:                                                                                      #
#   used to simulate workload on (LXC) virtualization infrastructure                          #
#                                                                                             #
# WORKLOAD TYPE:                                                                              #
#   DISKS                                                                                     #
###############################################################################################

# ####################### IMPORTS #######################
source ./virtualizer_functions/LxcManager.sh
# #######################################################

readonly wait_time_after_attach=10
readonly wait_time_after_detach=10

LxcWorkloads() {
  local count_disks=1
  local max_disks=50
  local disk_path="path/to/your/lxc/disks/disk"

  while true; do
    # attach
    for port in {1..3}; do
      local target="/mnt/disk$port"
      ATTACH_DISK "${disk_path}${count_disks}.img" "$port"

      if [[ "$count_disks" -eq "$max_disks" ]]; then
        count_disks=1
      else
        ((count_disks++))
      fi
      sleep $wait_time_after_attach
    done

    # detach
    for port in {1..3}; do
      DETACH_DISK "disk$port"
      sleep $wait_time_after_detach
    done
  done
}

LxcWorkloads