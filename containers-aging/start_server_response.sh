#!/usr/bin/env bash

server_response="./software-aging-v2/rejuvenation/machine_resources_monitoring/server-response-time.sh"

pids=() # Array para armazenar os PIDs dos processos

trap "EXIT" SIGINT SIGTERM

EXIT() {
    echo "Exiting..."
    for pid in "${pids[@]}"; do
        kill "$pid"
    done
    exit 0
}

run_server_response() {
    local ip_address="$1"
    local output_file="$2"
    "$server_response" "$ip_address" "$output_file" &
    pids+=($!)  # Adiciona o PID do processo à lista
}

run_server_response "192.168.0.101:8080" "docker_novo_ubuntu_velho.csv"
run_server_response "192.168.0.102:8080" "docker_novo_ubuntu_novo.csv"
run_server_response "192.168.0.103:8080" "podman_novo_ubuntu_novo.csv"
run_server_response "192.168.0.104:8080" "docker_novo_ubuntu_velho.csv"


# while true; do  # Ou um sleep de 11 dias
#     $time_for_exit
#     EXIT
# done

sleep 31680
EXIT