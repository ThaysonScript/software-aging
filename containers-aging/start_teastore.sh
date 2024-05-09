#!/usr/bin/env bash

ip_address=$(hostname -I | awk '{print $1}')

software=$1

$software run -e "HOST_NAME=$ip_address" -e "SERVICE_PORT=10000" -p 10000:8080 -d --restart=always docker.io/descartesresearch/teastore-registry

sleep 60

$software run -p 3306:3306 -d --restart=always docker.io/descartesresearch/teastore-db

sleep 60

$software run -e "REGISTRY_HOST=$ip_address" -e "REGISTRY_PORT=10000" -e "HOST_NAME=$ip_address" -e "SERVICE_PORT=1111" -e "DB_HOST=$ip_address" -e "DB_PORT=3306" -p 1111:8080 -d --restart=always docker.io/descartesresearch/teastore-persistence

sleep 60

$software run -e "REGISTRY_HOST=$ip_address" -e "REGISTRY_PORT=10000" -e "HOST_NAME=$ip_address" -e "SERVICE_PORT=2222" -p 2222:8080 -d --restart=always docker.io/descartesresearch/teastore-auth

sleep 60

$software run -e "REGISTRY_HOST=$ip_address" -e "REGISTRY_PORT=10000" -e "HOST_NAME=$ip_address" -e "SERVICE_PORT=3333" -p 3333:8080 -d --restart=always docker.io/descartesresearch/teastore-recommender

sleep 60

$software run -e "REGISTRY_HOST=$ip_address" -e "REGISTRY_PORT=10000" -e "HOST_NAME=$ip_address" -e "SERVICE_PORT=4444" -p 4444:8080 -d --restart=always docker.io/descartesresearch/teastore-image

sleep 60

$software run -e "REGISTRY_HOST=$ip_address" -e "REGISTRY_PORT=10000" -e "HOST_NAME=$ip_address" -e "SERVICE_PORT=8080" -p 8080:8080 -d --restart=always docker.io/descartesresearch/teastore-webui
