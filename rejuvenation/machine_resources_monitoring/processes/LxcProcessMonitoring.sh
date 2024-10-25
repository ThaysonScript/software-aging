#!/bin/bash

# Script to continuously monitor an LXC container process and log resource usage to a CSV file

VM_NAME="debian12"
log_file="logs/lxc_monitoring-${VM_NAME}.csv"
mkdir -p logs
echo "CPU;MEM;VMRSS;VSZ;Threads;Swap;Date_Time" > "$log_file"

while true; do
  pid=$(lxc-info -n "$VM_NAME" -pH)

  date_time=$(date +%d-%m-%Y-%H:%M:%S)

  if [ -n "$pid" ]; then
    data=$(pidstat -u -h -p $pid -T ALL -r 1 1 | sed -n '4p')
    thread=$(cat /proc/"$pid"/status | grep Threads | awk '{print $2}')
    cpu=$(echo "$data" | awk '{print $8}')
    mem=$(echo "$data" | awk '{print $14}')
    vmrss=$(echo "$data" | awk '{print $13}')
    vsz=$(echo "$data" | awk '{print $12}')
    swap=$(cat /proc/"$pid"/status | grep VmSwap | awk '{print $2}')

    echo "$cpu;$mem;$vmrss;$vsz;$thread;$swap;$date_time" >> "$log_file"
  else
    sleep 1
    echo "0;0;0;0;0;0;$date_time" >> "$log_file"
  fi
done