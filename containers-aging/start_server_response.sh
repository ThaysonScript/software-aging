#!/usr/bin/env bash

server_response="../rejuvenation/machine_resources_monitoring/server-response-time.sh"

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
    "$server_response" "$ip_address/tools.descartes.teastore.webui/" "$output_file" &
    pids+=($!)  # Adiciona o PID do processo à lista
}

run_server_response "192.168.0.105:8080" "debian12_docker_novo.csv"
run_server_response "192.168.0.106:8080" "ubuntu22_docker_velho.csv"
run_server_response "192.168.0.107:8080" "ubuntu24_podman.csv"
run_server_response "192.168.0.108:8080" "debian12_docker_velho.csv"
run_server_response "192.168.0.109:8080" "ubuntu22_podman.csv"
run_server_response "192.168.0.110:8080" "ubuntu24_docker_novo.csv"
run_server_response "192.168.0.111:8080" "debian12_podman.csv"
run_server_response "192.168.0.112:8080" "ubuntu22_docker_novo.csv"
run_server_response "192.168.0.113:8080" "ubuntu24_docker_velho.csv"

sleep infinity
EXIT