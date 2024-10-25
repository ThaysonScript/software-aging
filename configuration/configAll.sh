#!/usr/bin/env bash
# HOW TO USE:
#   source configAll.sh
# 
# DESCRIPTION:
#   USADO PARA DEFINIR AUTOCONFIGURAÇÃO DE VARIAVEIS DE AMBIENTE E TESTES PADRÕES

GlobalExports() {
    export ACTIVATE=1
}

# CREATE A FILE WITH ALL PRE CONFIGS
GeneratedFileConfig() {
    printf "%s\n\n" "######################## FILE CONFIGS - $filename ########################" >> "$filename".cfg
}

Lxc() {
    cat >> "$filename".cfg <<EOF
Linha 4
Linha 5
EOF
}

Xen() {
    cat >> "$filename".cfg <<EOF
################################## EXPORTS ##################################
export 
#############################################################################
EOF

}

Kvm() {
    cat >> "$filename".cfg <<EOF
Linha 4
Linha 5
EOF
}

Virtualbox() {
    cat >> "$filename".cfg <<EOF
Linha 4
Linha 5
EOF
}

Main() {
    local filename=$1

    GlobalExports
    GeneratedFileConfig "$filename"

    printf "\n%s\n" "[1] - LXC"
    printf "%s\n" "[2] - XEN"
    printf "%s\n" "[3] - KVM"
    printf "%s\n" "[4] - VBOX"
    read -p "[QUAL VIRTUALIZADOR CONFIGURAR?]: " virtualizer

    if [[ "$virtualizer" -eq 1 ]]; then
        Lxc
    
    elif [[ "$virtualizer" -eq 2 ]]; then
        Xen
    
    elif [[ "$virtualizer" -eq 3 ]]; then
        Kvm
    
    elif [[ "$virtualizer" -eq 4 ]]; then
        Virtualbox
    fi
}

rm -r *.cfg

read -p "[SET FOR SAVE FILENAME]: " filename
Main "$filename"