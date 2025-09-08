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
  local -a ATTACHED_DISKS=()

  while true; do
    # attach
    for count in {1..3}; do
      local disk="disk$count_disks.qcow2"

      ATTACH_DISK "$disk" "$disk_path/$disk" "/root/disk$count"

      ATTACHED_DISKS+=("$disk")
      # shellcheck disable=SC2182
      printf "\n" ""

      if [[ "$count_disks" -eq "$max_disks" ]]; then
        count_disks=1
      else
        ((count_disks++))
      fi
      sleep $wait_time_after_attach
    done

    # detach
    for disk in "${ATTACHED_DISKS[@]}"; do
      DETACH_DISK "$disk"
      sleep $wait_time_after_detach
      # shellcheck disable=SC2182
      printf "\n" ""
    done

    ATTACHED_DISKS=()
  
  done
}

LXC_WORKLOAD