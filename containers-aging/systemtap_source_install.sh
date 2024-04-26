#!/usr/bin/env bash

echo "Verifique se você está no diretorio /root: "; echo "Seu dir atual é: $(pwd)"; echo "Caso não, mude para ele!"

GET_SYSTEMTAP_SOURCE() {
    apt install git gcc g++ build-essential zlib1g-dev elfutils libdw-dev gettext -y || {
        echo "erro ao instalar dependencias para o systemtap"; echo "saindo"; exit 1
    }

    git clone "git://sourceware.org/git/systemtap.git" || {
        echo "erro ao tentar baixar o codigo fonte do systemtap a partir do repositório git"; echo "saindo..."; exit 1
    }

    cd "/root/systemtap" || {
        echo "erro ao tentar entrar no diretorio do systemtap"; echo "saindo..."; exit 1
    }


    ./configure || {
        echo "Este erro é proposital, copie e rode o ./configure com uma saida parecida com esta abaixo:"

        # shellcheck disable=SC2154
        echo "./configure 'PKG_CONFIG_PATH=/usr/lib/pkgconfig' python=':' pyexecdir='' python3='/usr/bin/python3' py3execdir='${exec_prefix}/lib/python3.11/site-packages' --prefix=/root/systemtap-5.0-8684"
        echo "saindo..."; exit 0
    }

    make all || {
        echo "erro ao tentar compilar o systemtap com make all"; echo "saindo"; exit 1
    }

    make install || {
        echo "erro ao tentar instalar compilação do systemtap com make install"; echo "saindo"; exit 1
    }

    echo "adicionando path do systemtap em /root/.bashrc"; echo "export PATH=\$PATH:/root/systemtap" >> "/root/.bashrc"

    echo "faca: source /root/.bashrc"; echo "verifique se a path foi adicionada com: echo $'PATH'"

    echo "Caso deseje executar como user sudo ou comum, faça: ( echo export PATH=\$PATH:/home/$(logname)/systemtap >> /home/$(logname)/.bashrc ) e faça ( source /home/$(logname)/.bashrc )"

    echo "concluido!!!"; exit 0
}

RUNNING_SMALL_SYSTEMTAP_TEST() {
    # shellcheck disable=SC2317
    stap -ve 'probe begin { log("hello world") exit () }'

    # shellcheck disable=SC2317
    stap -c df -e 'probe syscall.* { if (target()==pid()) log(name." ".argstr) }'
}

MAIN() {
    GET_SYSTEMTAP_SOURCE

    # shellcheck disable=SC2317
    echo "Deseja rodar um pequeno teste de verificação de instalação? [s]/[n]"
    # shellcheck disable=SC2317
    read -r -p "escolha: " escolha

    # shellcheck disable=SC2317
    [[ "$escolha" == "s" ]] && RUNNING_SMALL_SYSTEMTAP_TEST
}

MAIN
