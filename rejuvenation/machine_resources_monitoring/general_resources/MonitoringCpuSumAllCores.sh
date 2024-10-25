#!/usr/bin/env bash

SumCpuMetrics() {
    mpstat -P ALL 1 1 | awk -v date_time="$date_time" '
    /^[0-9]/ {

        # Replaces commas with periods to treat as floating point
        gsub(",", ".", $3);
        gsub(",", ".", $4);
        gsub(",", ".", $5);
        gsub(",", ".", $6);
        gsub(",", ".", $7);
        gsub(",", ".", $8);
        gsub(",", ".", $9);
        gsub(",", ".", $10);
        gsub(",", ".", $11);
        gsub(",", ".", $12);
        
        # Accumulates column values
        if (NR > 1) {
            usr += $3 + 0;
            nice += $4 + 0;
            sys += $5 + 0;
            iowait += $6 + 0;
            irq += $7 + 0;
            soft += $8 + 0;
            steal += $9 + 0;
            guest += $10 + 0;
            gnice += $11 + 0;
            idle += $12 + 0;

            count++;
        }
    }

    END {
        # Calculates the average for the %idle column only
        avg_idle = (count > 0) ? (idle / count) : 0;

        # Calculates the average only for Calculates the total CPU usage for the %idle column
        total_cpu = 100 - avg_idle;

        # Prints the header and data in CSV format separated by ;
        printf "%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%s\n",
            usr, nice, sys, iowait, irq, soft, steal, guest, gnice, avg_idle, total_cpu, date_time

    }' >> logs/cpu_monitoring_sumAllCores.csv
}

SumCpuMetrics