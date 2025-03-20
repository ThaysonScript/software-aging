#!/usr/bin/env bash

# Script to monitor the status of the server by sending HTTP requests to http://localhost:8080
# and logging downtime information to a CSV file

# ############################## IMPORTS #############################
if [[ "$VIRTUALIZER_TYPE" == "vbox" ]]; then
    source ../../virtualizer_functions/vbox_functions.sh

elif [[ "$VIRTUALIZER_TYPE" == "kvm" ]]; then
    source ../../virtualizer_functions/kvm_functions.sh

elif [[ "$VIRTUALIZER_TYPE" == "xen" ]]; then
    source ../../virtualizer_functions/xen_functions.sh

elif [[ "$VIRTUALIZER_TYPE" == "lxd" ]]; then
    source ../../virtualizer_functions/lxd_functions.sh
fi
# ####################################################################

set -e
trap 'echo "Erro detectado no comando: "; set -x;$BASH_COMMAND; set +x' ERR

started_at=0
is_offline=0
down_count=0

VIRTUALIZER_TYPE=$1

case $VIRTUALIZER_TYPE in
  "vbox")
    url="http://localhost:8080"
    ;;
  "kvm")
    #url="192.168.122.114"
    url="$GET_HOST_IP:8080"
    #url="192.168.1.3:8080"
    ;;
  "xen")
    url="http://172.20.101.23:8080"
    #http://172.20.100.178:80
    ;;
  "lxd")
    echo "No information available for LXC at the moment"
    exit 1
    ;;
  *)
    echo "Unknown virtualizer type"
    exit 1
    ;;
esac

while true; do
  if [ "$is_offline" -eq 0 ]; then
    started_at=$(date +%s)
  fi

  response=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "$url")

  if [ "$response" -eq 200 ]; then
    if [ "$is_offline" -eq 1 ]; then
      date_time=$(date +%d-%m-%Y-%H:%M:%S)
      end_time=$(date +%s)
      offline_time=$((end_time - started_at))
      ((down_count++))
      echo "$down_count;$offline_time;$date_time" >>logs/machineHost_server_status.csv
      is_offline=0
    fi
  else
    is_offline=1
  fi
  sleep 1
done
