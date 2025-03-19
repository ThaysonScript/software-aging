#!/usr/bin/env bash
# usage:
#   $ bash workload_kvm.sh

######################################## KVM - WORKLOAD #######################################
# ABOUT:                                                                                      #
#   used to simulate workload on (kvm) virtualization infrastructure                        #
#                                                                                             #
# WORKLOAD TYPE:                                                                              #
#   DISKS                                                                                     #
###############################################################################################

# ####################### IMPORTS #######################
source ./virtualizer_functions/kvm_functions.sh
# #######################################################

readonly wait_time_after_attach=10
readonly wait_time_after_detach=10

KVM_WORKLOAD() {
    local attach_count_disks=1
    local detach_count_disks=1
    local disk
    disk="$(find / -name disk1.qcow2)"

    local disk_path
    disk_path="$(dirname "$disk")/disk"

    local max_disks=50
    local identificador=("b" "c" "d")

    while true; do
        # detach loop
        for i in {1..3}; do
            DETACH_DISK "vd${identificador[$i - 1]}"

            if [[ "$detach_count_disks" -eq "$max_disks" ]]; then
                detach_count_disks=1
            else
                ((detach_count_disks++))
            fi
            sleep $wait_time_after_detach

        done

        # attach loop
        for i in {1..3}; do
            ATTACH_DISK "${disk_path}${attach_count_disks}.qcow2" "vd${identificador[$i - 1]}"

            if [[ "$attach_count_disks" -eq "$max_disks" ]]; then
                attach_count_disks=1
            else
                ((attach_count_disks++))
            fi
            sleep $wait_time_after_attach
        done

    done
}

KVM_WORKLOAD