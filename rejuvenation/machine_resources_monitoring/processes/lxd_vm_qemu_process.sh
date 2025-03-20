#!/usr/bin/env bash

# Script to continuously monitor an LXC container process and log resource usage to a CSV file
while true; do
  # Obtém o ID da VM
  vm_id=$(pgrep -f qemu-system-x86)
  DATETIME=$(date +%d-%m-%Y-%H:%M:%S)

  if [ -n "$vm_id" ]; then
    data=$(pidstat -u -h -p "$vm_id" -T ALL -r 1 1 | sed -n '4p')
    thread=$(cat /proc/"$vm_id"/status | grep Threads | awk '{print $2}')

    cpu=$(echo "$data" | awk '{print $8}')
    mem=$(echo "$data" | awk '{print $14}')
    vmrss=$(echo "$data" | awk '{print $13}')
    vsz=$(echo "$data" | awk '{print $12}')
    swap=$(cat /proc/"$vm_id"/status | grep Swap | awk '{print $2}')

    echo "$cpu;$mem;$vmrss;$vsz;$thread;$swap;$DATETIME" >>logs/lxd_vm_qemu_process.csv
  else
    sleep 1
    echo "0;0;0;0;0;0;0" >>logs/lxd_vm_qemu_process.csv
  fi
done
