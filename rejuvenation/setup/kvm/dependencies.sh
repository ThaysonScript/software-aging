#!/usr/bin/env bash
# usage:
#   $ bash dependencies.sh

# ############################## IMPORTS #############################
source ../../machine_resources_monitoring/general_dependencies.sh
source ../../virtualizer_functions/kvm_functions.sh
# ####################################################################

readonly XML_FILE_PATH="/var/lib/libvirt/images/$VM_NAME.xml"


INSTALL_KVM_LIBVIRT_DEPENDENCIES() {
    local flag

    reset

    printf "[1] - instalar dependencias a nivel de host com interface\n[2] - instalar dependencias a nivel de host sem interface\n[3] - remover pacotes\n"
    read -rp "escolha: " escolha

    if ! which qemu-system-x86_64 >/dev/null; then

        # host com interface
        if [[ "$escolha" -eq 1 ]]; then
            # apt install qemu-system libvirt-daemon-system -y
            apt install qemu-system -y
            apt install qemu-utils -y
            apt install libvirt-daemon-system -y
            apt install virt-manager -y

            flag=1

        # host sem interface
        elif [[ "$escolha" -eq 2 ]]; then
            # apt install --no-install-recommends qemu-system qemu-utils libvirt-daemon-system -y
            apt install qemu-system -y
            apt install qemu-utils -y
            apt install libvirt-daemon-system -y

            flag=2

        else
            printf "\nopcao invalida\n"
            exit 1
        fi

    fi

    if [[ "$escolha" -eq 3 ]]; then
        apt remove qemu* -y

        apt remove libvirt* -y || {
            # Pacote a ser removido
            pacote="libvirt*"

            # Verifica se o pacote está instalado
            if apt list --installed "$pacote" 2>/dev/null | grep -q "$pacote"; then
                apt remove "$pacote" -y

            else
                printf "%s" "Pacote $pacote não encontrado. Ignorando."
            fi
        }

        printf "\nremova as pastas manualmente de libvirt com dpkg -r pacote\n\n"

        apt remove virt-manager virtinst dnsmasq -y; apt autoremove -y

    else
        # add root user group on libvirt
        sudo adduser "$USER" libvirt        # caso exista sudo
        usermod -aG libvirt "$USER"         # caso tenha somente root user

        echo -e "seu usuario foi definido? caso nao verifique a adicao de grupo de usuarios."
        getent group libvirt
        getent group libvirt-qemu

        apt install dnsmasq -y

        # Make Network active and auto-restart
        virsh net-start default
        virsh net-autostart default
    fi

    read -rp "ja criou a vm com sua maquina com interface: debian12? [s/n]: " criado

    if [[ "$criado" == "s" && "$flag" -eq 1 ]]; then
        virt-viewer --connect qemu:///session --wait "$VM_NAME"
        virsh dumpxml "$VM_NAME" > "$XML_FILE_PATH"

    else
        printf "%s" "crie a vm: $VM_NAME; pode executar novamente a dependencies.sh para configuracao inicial da debian12\n"
    fi
}

INTERNAL_DEPENDENCIES() {
    # MAKE INSTALL
    [[ ! $(which make) ]] && {
        echo "INSTALLING MAKE ......."
        apt install make -y
    }

    INSTALL_KVM_LIBVIRT_DEPENDENCIES
}

START_DEPENDENCIES() {
    INTERNAL_DEPENDENCIES                  # INTERNAL DEPENDENCIES
    INSTALL_GENERAL_DEPENDENCIES        # EXTERNAL DEPENDENCIES
}

START_DEPENDENCIES
