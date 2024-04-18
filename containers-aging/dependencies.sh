#!/usr/bin/env bash

source /etc/os-release
DISTRO_ID="$ID"
DISTRO_CODENAME="$VERSION_CODENAME"
SYSTEM_VERSION="$VERSION_ID"
KERNEL_VERSION=$(uname -r)

ADD_UBUNTU_DOCKER_REPOSITORY() {
  $(. /etc/os-release && echo "$VERSION_CODENAME") "stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
}

ADD_DEBIAN_DOCKER_REPOSITORY() {
  tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
}

INSTALL_DOCKER_UBUNTU_OLD () {
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu" \
    "$(ADD_UBUNTU_DOCKER_REPOSITORY)"

  VERSION_STRING="5:20.10.13~3-0~ubuntu-$DISTRO_CODENAME"
  apt-get install docker-ce="$VERSION_STRING" docker-ce-cli="$VERSION_STRING" containerd.io docker-buildx-plugin docker-compose-plugin

}

INSTALL_DOCKER_UBUNTU_NEW () {
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu" \
    "$(ADD_UBUNTU_DOCKER_REPOSITORY)"

  VERSION_STRING="5:26.0.1-1~ubuntu.$SYSTEM_VERSION~$DISTRO_CODENAME"
  apt-get install docker-ce="$VERSION_STRING" docker-ce-cli="$VERSION_STRING" containerd.io docker-buildx-plugin docker-compose-plugin
}


INSTALL_DOCKER_DEBIAN_OLD () {
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  bullseye stable" | \
  ADD_DEBIAN_DOCKER_REPOSITORY

  VERSION_STRING="5:20.10.13~3-0~debian-bullseye"
  apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
}

INSTALL_DOCKER_DEBIAN_MEW () {
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  bullseye stable" | \
  ADD_DEBIAN_DOCKER_REPOSITORY

  VERSION_STRING="5:26.0.1-1~debian.11~bullseye"
  apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
}

INSTALL_PYTHON_DEPENDENCIES() {
  apt install python3.11 python3.11-venv || {
    printf "%s\n" "Error: python install dependencies error!"
    exit 1
  }

  python3.11 -m venv env

  source env/bin/activate

  pip install PyYAML
}

INSTALL_PYTHON_DEPENDENCIES

echo -e "Would you like to install KVM? 1 - [Yes] 2 - [No]"
read -r vm
if [ "$vm" == "1" ]; then
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

echo -e "Would you like to install monitoring libraries 1 - [Yes] 2 - [No]"
read -r choice
if [ "$choice" -eq 1 ]; then
  apt install linux-headers-"$KERNEL_VERSION" linux-image-"$KERNEL_VERSION"-dbg gnupg wget sysstat systemtap -y
  cp /proc/kallsyms /boot/System.map-"$KERNEL_VERSION"
fi

echo -e "Which service are you using? 1 - [Docker] 2 - [Podman] 3 - None"
read -r service
if [ "$service" == "1" ]; then
  echo -e "Are you using the latest version of Docker? 1 - [yes] 2 - [no]"
  read -r service

  apt-get install ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  printf "%s\n" -e "Do you want to install the new [1] or old [2] version of docker?"
  printf "%s\n" -e "new version - [1]"
  printf "%s\n" "old version [2]"
  read -r -p "choice: " stap

  if [ "$stap" == "1" ]; then
    case $DISTRO_ID in
    "ubuntu") INSTALL_DOCKER_UBUNTU_NEW;;
    "debian") INSTALL_DOCKER_DEBIAN_MEW;;
    esac
  else
    case $DISTRO_ID in
    "ubuntu") INSTALL_DOCKER_UBUNTU_OLD;;
    "debian") INSTALL_DOCKER_DEBIAN_OLD;;
    esac
  fi

  groupadd docker
  usermod -aG docker "$USER"
 
  newgrp docker & pid=$!; echo "subshell dead newgrp docker: $pid"; kill "$pid"; echo "pid is dead!"

  docker run hello-world

elif [ "$service" == "2" ]; then
  apt install git gcc make wget -y
  apt-get install -y libsystemd-dev libgpgme-dev libseccomp-dev -y
  echo "export PKG_CONFIG_PATH=/usr/lib/pkgconfig" >> ~/.bashrc
  source ~/.bashrc

  wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz

  echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
  source ~/.bashrc

  echo "Installing Podman..."
  git clone https://github.com/containers/podman.git
  cd podman || exit 1
  git checkout v4.9
  make install.tools
  make binaries

  echo "export PATH=$PATH:~/podman/bin" >> ~/.bashrc
  source ~/.bashrc

  pip install podman-compose

  podman run docker.io/hello-world
else
  echo "Invalid option, exiting..."
  exit 1
fi

echo "Finished and venv is active, change the config.yaml file"