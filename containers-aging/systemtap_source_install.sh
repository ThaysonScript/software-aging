#!/usr/bin/env bash

MAIN() {

    echo "baixar o repo do systemtap; mover para a vm; fazer ./configure; verificar as dependencias e instalar; fazer make all; make intall; adicionar a path no .bashrc

        dependencias encontradas ao executar ./configure:
        apt install gcc g++ build-essential zlib1g-dev elfutils libdw-dev gettext

        depois de instalar as dependencias rode o ./configure com:
        ./configure  'PKG_CONFIG_PATH=/usr/lib/pkgconfig' python=':' pyexecdir='' python3='/usr/bin/python3' py3execdir='${exec_prefix}/lib/python3.11/site-packages' --prefix=/root/systemtap-5.1-38>


        depois faca:
        make all

        depois faca:
        make install

        por ultimo faca:
        echo "export PATH=$PATH:/root/systemtap" >> /root/.bashrc

        e

        source /root/.bashrc
"
}

MAIN
