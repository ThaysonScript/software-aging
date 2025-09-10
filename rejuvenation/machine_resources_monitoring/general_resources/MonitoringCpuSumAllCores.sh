#!/usr/bin/env bash

SumCpuMetrics() {
    mpstat -P ALL 1 1 | awk -v date_time="$date_time" '
    /^[0-9]/ && $2 != "all" {
        # Accumulates column values
        if (NR > 1) {
            usr += $3;
            nice += $4;
            sys += $5;
            iowait += $6;
            soft += $8;

            count++;
        }
    }

    END {
        # Calculates the average for the %idle column only
        avg_idle = (count > 0) ? (idle / count) : 0;

        # Prints the header and data in CSV format separated by ;
        printf "%.2f;%.2f;%.2f;%.2f;%.2f;%s\n",
            usr, nice, sys, iowait, soft, date_time

    }' >> logs/cpu_monitoring_sumAllCores.csv
}

SumCpuMetrics