#!/usr/bin/env bash
echo "NAME;STATE;CPU(sec);CPU(%);MEM(k);MEM(%);MAXMEM(k);MAXMEM(%);VCPUS;NETS;NETTX(k);NETRX(k);VBDS;VBD_OO;VBD_RD;VBD_WR;VBD_RSECT;VBD_WSECT;SSID" > "logs/xenDomain0MetricsMonitoring.csv"

xentop -b -d 1 | while read -r line; do
    if echo "$line" | grep -q "Domain-0"; then
        echo "$line" | awk '{
            print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8";"$9";"$10";"$11";"$12";"$13";"$14";"$15";"$16";"$17";"$18";"$19
        }' >> "logs/xenDomain0MetricsMonitoring.csv"
    fi
done
