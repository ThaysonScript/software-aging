#!/usr/bin/env bash
# usage example:
#   ./server-response-time.sh 192.168.0.109 8080

ADDRESS=$1    # define server address
FILE_NAME=$2  # define file name

PRINT_USAGE() {
  local ip_example; ip_example=$(hostname -I | awk '{print $1}')

  echo "IP USAGE EXAMPLE: $ip_example:8080"
  echo "FILE_NAME EXAMPLE: $0"

  echo "bash server-response-time.sh 192.168.0.109 8080"
}

CHECK_ARGUMENTS() {
  if [ "$#" -ne 2 ]; then
    PRINT_USAGE
    echo "favor: passar 2 argumentos ao script"
    exit 1
  fi

  # Create the CSV file header
  echo "date_time;response_time" >"$FILE_NAME"
}

CHECK_ARGUMENTS "$@"

# Infinite loop to measure response time
while true; do
  timestamp=$(date +%d-%m-%Y-%H:%M:%S)  # capture current time in format ( +%d-%m-%Y-%H:%M:%S ) - timestamps

  # Make the HTTP request and capture the response time
  response=$(curl -w "%{http_code}  %{time_total}" -o /dev/null -s "http://$ADDRESS")
  code=$(echo "$response" | awk '{print $1}')
  response_time=$(echo "$response" | awk '{print $2}')

  if [ ! "$code" -eq 200 ]; then
    response_time="-1"
  fi

  # Add the timestamp and response time to the CSV file
  echo "$timestamp;$response_time" >>"$FILE_NAME"

  sleep 1 # wait one seconds for next monitoring request 
done
