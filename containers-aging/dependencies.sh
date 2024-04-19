#!/usr/bin/env bash

# shellcheck disable=SC1091
source /etc/os-release

readonly DISTRO_ID="$ID"
readonly DISTRO_CODENAME="$VERSION_CODENAME"
readonly SYSTEM_VERSION="$VERSION_ID"

KERNEL_VERSION=$(uname -r)

ADD_UBUNTU_DOCKER_REPOSITORY() {
  $(. /etc/os-release && echo "$VERSION_CODENAME") "stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt-get update
}

ADD_DEBIAN_DOCKER_REPOSITORY() {
  tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt-get update
}

INSTALL_DOCKER_UBUNTU_OLD() {
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu" \
    "$(ADD_UBUNTU_DOCKER_REPOSITORY)"

  VERSION_STRING="5:20.10.13~3-0~ubuntu-$DISTRO_CODENAME"
  apt-get install docker-ce="$VERSION_STRING" docker-ce-cli="$VERSION_STRING" containerd.io docker-buildx-plugin docker-compose-plugin

}

INSTALL_DOCKER_UBUNTU_NEW() {
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu" \
    "$(ADD_UBUNTU_DOCKER_REPOSITORY)"

  VERSION_STRING="5:26.0.1-1~ubuntu.$SYSTEM_VERSION~$DISTRO_CODENAME"
  apt-get install docker-ce="$VERSION_STRING" docker-ce-cli="$VERSION_STRING" containerd.io docker-buildx-plugin docker-compose-plugin
}

INSTALL_DOCKER_DEBIAN_OLD() {
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  bullseye stable" |
    ADD_DEBIAN_DOCKER_REPOSITORY

  VERSION_STRING="5:20.10.13~3-0~debian-bullseye"
  apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
}

INSTALL_DOCKER_DEBIAN_NEW() {
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  bullseye stable" |
    ADD_DEBIAN_DOCKER_REPOSITORY

  VERSION_STRING="5:26.0.1-1~debian.11~bullseye"
  apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
}

INSTALL_PYTHON_DEPENDENCIES() {
  echo -e "installing python dependencies...."

  apt install python3.11 python3.11-venv || {
    printf "%s\n" "Error: python install dependencies error!"
    exit 1
  }

  python3.11 -m venv env

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
  printf "\n%s\n" "Would you like to install monitoring libraries?"
  printf "%s\n" "Yes - [1]"
  printf "%s\n" "No - [2]"

  read -r -p "choice: " choice
  if [ "$choice" -eq 1 ]; then
    apt install linux-headers-"$KERNEL_VERSION" linux-image-"$KERNEL_VERSION"-dbg gnupg wget sysstat systemtap -y
    cp /proc/kallsyms /boot/System.map-"$KERNEL_VERSION"

  else
    echo -e "not installing library monitoring dependencies!"
  fi
}

INSTALL_DOCKER_DEPENDENCIES() {
  apt-get install ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
}

DOCKER_INSTALL() {
  # reset

  printf "\n%s\n" "Do you want to install the new version or old version of docker?"
  printf "%s\n" "new version - [1]"
  printf "%s\n" "old version - [2]"
  printf "%s\n" "None - [Another Keyboard]"

  read -r -p "choice: " version_choice
  if [ "$version_choice" -eq 1 ]; then
    case $DISTRO_ID in
    "ubuntu")
      INSTALL_DOCKER_UBUNTU_NEW
      ;;

    "debian")
      INSTALL_DOCKER_DEBIAN_NEW
      ;;
    esac

  elif [ "$version_choice" -eq 2 ]; then
    case $DISTRO_ID in
    "ubuntu")
      INSTALL_DOCKER_UBUNTU_OLD
      ;;

    "debian")
      INSTALL_DOCKER_DEBIAN_OLD
      ;;
    esac

  else
    printf "%s\n" "Error - error docker install"

  fi

  groupadd docker
  usermod -aG docker "$USER"

  newgrp docker &
  pid=$!
  echo "subshell dead newgrp docker: $pid"
  kill "$pid"
  echo "pid is dead!"

  docker run hello-world
}

PODMAN_INSTALL_DEPENDENCIES() {
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

  apt install git gcc make wget pkg-config conmon -y
  apt-get install -y libsystemd-dev libgpgme-dev libseccomp-dev -y

  wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
}

PODMAN_INSTALL() {
  # reset

  echo "Installing Podman..."

  git clone https://github.com/containers/podman.git

  cd podman || exit 1

  git checkout v4.9

  make install.tools
  make binaries

  pip install podman-compose

  podman run docker.io/hello-world
}

ADD_PATH_PACKAGES() {
  echo "export PKG_CONFIG_PATH=/usr/lib/pkgconfig" >>"$HOME"/.bashrc
  echo "export PATH=\$PATH:/usr/local/go/bin" >>"$HOME"/.bashrc
  echo "export PATH=\$PATH:/home/$(logname)/podman/bin" >>"$HOME"/.bashrc
}

MAIN() {
  # reset

  INSTALL_PYTHON_DEPENDENCIES
  INSTALL_QEMU_KVM_DEPENDENCIES
  INSTALL_LIBRARIES_FOR_MONITORING

  printf "%s\n" "Which service are you using?"
  printf "%s\n" "Docker - [1]"
  printf "%s\n" "Podman - [2]"
  printf "%s\n" "None - [Another Keyboard]"

  read -r -p "choice: " service
  if [ "$service" -eq 1 ]; then
    INSTALL_DOCKER_DEPENDENCIES
    DOCKER_INSTALL

  elif [ "$service" -eq 2 ]; then
    PODMAN_INSTALL_DEPENDENCIES
    PODMAN_INSTALL

  else
    echo "Invalid option or none option selection, exiting..."
    exit 1
  fi

  # reset
  printf "%s\n" "autoremoving packages not necessary"
  apt autoremove -y

  echo "Finished and venv is active, change the config.yaml file"
}

ADD_PATH_PACKAGES && echo "faca: source /root/.bashrc" && echo "execute novamente o mesmo codigo e depois retire ou comente esta linha toda" && exit 0

MAIN
