#!/usr/bin/env bash

# shellcheck disable=SC1091
source /etc/os-release

readonly DISTRO_ID="$ID"
readonly DISTRO_CODENAME="$VERSION_CODENAME"
readonly SYSTEM_VERSION="$VERSION_ID"

export PATH=$PATH:/usr/local/go/bin
export PKG_CONFIG_PATH=/usr/lib/pkgconfig

KERNEL_VERSION=$(uname -r)
BASE_DIR=$(pwd)

RESET_TO_ORIGINAL_DIR() {
  cd "$BASE_DIR" || exit 1
}

ADD_UBUNTU_DOCKER_REPOSITORY() {
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu" \
  "jammy stable" > /etc/apt/sources.list.d/docker.list

  apt-get update
}

ADD_DEBIAN_DOCKER_REPOSITORY() {
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  bullseye stable" >> /etc/apt/sources.list.d/docker.list
  apt-get update
}

INSTALL_PYTHON_DEPENDENCIES() {
  echo -e "installing python dependencies...."

  apt install python3.11 python3.11-venv

  python3.11 -m venv env

  echo "export PATH=\$PATH:/root/podman/bin" >> env/bin/activate

  source env/bin/activate

  pip install PyYAML
}

INSTALL_QEMU_KVM_DEPENDENCIES() {
  printf "\n%s\n" "Would you like to install KVM?"
  printf "%s\n" "Yes - [1]"
  printf "%s\n" "No - [2]"

  read -r -p "choice: " install_kvm
  if [ "$install_kvm" -eq 1 ]; then
    echo "Installing KVM..."

    apt install --no-install-recommends qemu-system -y
    apt install --no-install-recommends qemu-utils -y
    apt install --no-install-recommends libvirt-daemon-system -y

    # add root user group on libvirt
    sudo adduser "$USER" libvirt

    # Make Network active and auto-restart
    virsh net-start default
    virsh net-autostart default
  fi
}

INSTALL_LIBRARIES_FOR_MONITORING() {
  reset
  printf "\n%s\n" "Would you like to install monitoring libraries?"
  printf "%s\n" "Yes - [1]"
  printf "%s\n" "No - [2]"

  read -r -p "choice: " choice
  if [ "$choice" -eq 1 ]; then
    apt install gnupg curl wget sysstat -y

    if [ "$DISTRO_ID" == "ubuntu" ]; then
       apt install ubuntu-dbgsym-keyring -y && {
        echo "deb http://ddebs.ubuntu.com $DISTRO_CODENAME main restricted universe multiverse
        deb http://ddebs.ubuntu.com $DISTRO_CODENAME-updates main restricted universe multiverse
        deb http://ddebs.ubuntu.com $DISTRO_CODENAME-proposed main restricted universe multiverse" > "/etc/apt/sources.list.d/ddebs.list"

        apt update
      }

      apt install linux-headers-"$KERNEL_VERSION" linux-image-"$KERNEL_VERSION"-dbgsym gcc -y

    else
      apt install linux-headers-"$KERNEL_VERSION" linux-image-"$KERNEL_VERSION"-dbg -y

    fi

    cp /proc/kallsyms /boot/System.map-"$KERNEL_VERSION"

    COMPILE_SYSTEMTAP

  else
    echo -e "not installing library monitoring dependencies!"
  fi
}

INSTALL_DOCKER(){
  VERSION_STRING=$1
  apt install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
}

DOCKER() {
  apt install ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  reset

  printf "\n%s\n" "Do you want to install the new version or old version of docker?"
  printf "%s\n" "new version - [1]"
  printf "%s\n" "old version - [2]"
  printf "%s\n" "None - [Another Keyboard]"

  read -r -p "choice: " version_choice
  if [ "$version_choice" -eq 1 ]; then
    case $DISTRO_ID in
    "ubuntu")
      ADD_UBUNTU_DOCKER_REPOSITORY
      INSTALL_DOCKER "5:26.0.1-1~ubuntu.22.04~jammy"
      ;;

    "debian")
      ADD_DEBIAN_DOCKER_REPOSITORY
      INSTALL_DOCKER "5:26.0.1-1~debian.11~bullseye"
      ;;
    esac

  elif [ "$version_choice" -eq 2 ]; then
    case $DISTRO_ID in
    "ubuntu")
      ADD_UBUNTU_DOCKER_REPOSITORY
      INSTALL_DOCKER "5:20.10.13~3-0~ubuntu-jammy"
      ;;

    "debian")
      ADD_DEBIAN_DOCKER_REPOSITORY
      INSTALL_DOCKER "5:20.10.13~3-0~debian-bullseye"
      ;;
    esac

  else
    printf "%s\n" "Error - error docker install"

  fi

  docker --version
}

COMPILE_PODMAN() {
  #SETTINGS
  mkdir -p /etc/containers

  if [ ! -f "/etc/containers/policy.json" ]; then
    touch /etc/containers/policy.json

    cat <<EOF >/etc/containers/policy.json
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ]
}
EOF
  fi

  apt install catatonit git gcc make curl wget pkg-config conmon crun containernetworking-plugins iptables -y
  apt install -y libsystemd-dev libgpgme-dev libseccomp-dev -y

  wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz

  #COMPILE
  cd /root || exit
  git clone https://github.com/containers/podman.git
  cd podman || exit 1
  git checkout v4.9
  make install.tools
  make binaries
  export PATH=$PATH:/root/podman/bin
  echo "export PATH=\$PATH:/root/podman/bin" >> "/root/.bashrc"
  echo "export PATH=\$PATH:/root/podman/bin" >> "$BASE_DIR/env/bin/activate"
  podman --version
  RESET_TO_ORIGINAL_DIR
}

COMPILE_SYSTEMTAP() {
    cd /root || exit
    apt install git gcc g++ build-essential zlib1g-dev elfutils libdw-dev gettext -y
    git clone "git://sourceware.org/git/systemtap.git"
    cd "systemtap" || exit
    ./configure
    make clean
    make all
    make install
    RESET_TO_ORIGINAL_DIR
}

INSTALL_QEMU_KVM_DEPENDENCIES
INSTALL_PYTHON_DEPENDENCIES
INSTALL_LIBRARIES_FOR_MONITORING

printf "%s\n" "Which service are you using?"
printf "%s\n" "Docker - [1]"
printf "%s\n" "Podman - [2]"
printf "%s\n" "None - [Another Keyboard]"

read -r -p "choice: " service
if [ "$service" -eq 1 ]; then
  DOCKER

elif [ "$service" -eq 2 ]; then
  COMPILE_PODMAN
fi

apt autoremove -y
chmod a+wrx start_teastore.sh