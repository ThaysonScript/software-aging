#!/usr/bin/env bash

######################################## LXC - WORKLOAD #######################################
# ABOUT:                                                                                      #
#   used to simulate workload on (LXC) virtualization infrastructure                          #
#                                                                                             #
# WORKLOAD TYPE:                                                                              #
#   DISKS                                                                                     #
###############################################################################################

# ####################### IMPORTS #######################
source ./virtualizer_functions/lxc_functions.sh
# #######################################################

readonly wait_time_after_attach=10
readonly wait_time_after_detach=10

LXC_WORKLOAD() {
  local count_disks=1
  local max_disks=50
  local disk_path="/root/software-aging/rejuvenation/setup/lxd/disks_lxc"

  while true; do
    # attach
    for count in {1..3}; do
      local disk="disk$count.qcow2"

      ATTACH_DISK "$disk" "$disk_path/$disk" "/root/disk$count"

      if [[ "$count_disks" -eq "$max_disks" ]]; then
        count_disks=1
      else
        ((count_disks++))
      fi
      sleep $wait_time_after_attach
    done

    # detach
    for count in {1..3}; do
      DETACH_DISK "disk$count.qcow2"
      sleep $wait_time_after_detach
    done
  done
}

LXC_WORKLOAD