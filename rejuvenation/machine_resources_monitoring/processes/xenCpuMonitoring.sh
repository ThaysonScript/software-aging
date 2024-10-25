#!/usr/bin/env bash

# execute in batch file
xentop -b -d 3 | while read -r line; do
    # Verifica se a linha contém "xenDebian"
    if echo "$line" | grep -q "xenDebian"; then
        # Substitui múltiplos espaços por ; e remove espaços extras
        echo "$line" | sed 's/ \+/;/g' >> "logs/xenCpuMonitoring.csv"
    fi
done

# #!/usr/bin/env bash
# echo "NAME;STATE;CPU(sec);CPU(%);MEM(k);MEM(%);MAXMEM(k);MAXMEM(%);VCPUS;NETS;NETTX(k);NETRX(k);VBDS;VBD_OO;VBD_RD;VBD_WR;VBD_RSECT;VBD_WSECT;SSID" > "logs/xenCpuMonitoring.csv"

# xentop -b -d 3 | while read -r line; do
#     if echo "$line" | grep -q "xenDebian"; then
#         cleaned_line=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//;s/[ \t][ \t]*/;/g')
#         echo "$cleaned_line" >> "logs/xenCpuMonitoring.csv"
#     fi
# done
