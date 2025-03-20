#!/usr/bin/env bash


while true; do
  service_id=$(pgrep -f /usr/bin/lxd | awk 'NR==1 {print}')  # Obtém o ID do servico
  DATETIME=$(date +%d-%m-%Y-%H:%M:%S)

  if [ -n "$service_id" ]; then
    data=$(pidstat -u -h -p "$service_id" -T ALL -r 1 1 | sed -n '4p')

    cpu=$(echo "$data" | awk '{print $8}')
    mem=$(echo "$data" | awk '{print $14}')
    vsz=$(echo "$data" | awk '{print $12}')
    rss=$(echo "$data" | awk '{print $13}')
    thread=$(cat /proc/"$service_id"/status | grep Threads | awk '{print $2}')
    swap=$(cat /proc/"$service_id"/status | grep Swap | awk '{print $2}')

    echo "$cpu;$mem;$vsz;$rss;$thread;$swap;$DATETIME" >>logs/lxd_group_process_monitoring.csv
  else
    sleep 1
    echo "0;0;0;0;0;0;0" >>logs/lxd_group_process_monitoring.csv
  fi
done
