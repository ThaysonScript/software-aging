#!/usr/bin/env bash

xentop -b -d 1 | while read -r line; do
    if echo "$line" | grep -q "xenDebian"; then
        echo "$line" | awk '{
            print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8";"$9";"$10";"$11";"$12";"$13";"$14";"$15";"$16";"$17";"$18";"$19
        }' >> "logs/xenVmMetricsMonitoring.csv"
    fi
done
