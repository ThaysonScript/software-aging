#!/usr/bin/env bash

server_response="./software-aging-v2/rejuvenation/machine_resources_monitoring/server-response-time.sh"

time_for_exit=$( sleep 31680 )

pids=() #Aqui deve ser um array

trap "exit" SIGINT SIGTERM

EXIT() {
	for pid in pids; do
		kill "$pid"
	done
}

pids+=($($server_response "192.168.0.101:8080" "docker_novo_ubuntu_velho.csv" &))
pids+=($($server_response "192.168.0.102:8080" "docker_novo_ubuntu_novo.csv" &))
pids+=($($server_response "192.168.0.103:8080" "podman_novo_ubuntu_novo.csv" &))
pids+=($($server_response "192.168.0.104:8080" "docker_novo_ubuntu_velho.csv" &))


while true; do  # Ou um sleep de 11 dias
    $time_for_exit
    EXIT
done