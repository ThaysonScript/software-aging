#!/usr/bin/env bash

######################################## XEN FUNCTIONS ########################################
# Universidade Federal do Agreste de Pernambuco                                               #
# Uname Research Group                                                                        #
#                                                                                             #
# ABOUT:                                                                                      #
#   utilities for managing xen virtual machines                                               #
###############################################################################################

VM_NAME="xenDebian"
HOST_IP="$(hostname -I | awk '{print $1}')"

# FUNCTION=TURN_VM_OFF()
# DESCRIPTION:
#   Tries to turn off the virtual machine
TURN_VM_OFF() {
  xl shutdown "$VM_NAME"
  sleep 10 
}

# FUNCTION=DELETE_VM()
# DESCRIPTION:
#   Deletes the DomU /etc/xen/xenDebian.cfg configuration file and all associated LVM volumes (swap and root disk) located in vg0
DELETE_VM() {
  xen-delete-image --lvm=vg0 "$VM_NAME"
}

# FUNCTION=GRACEFUL_REBOOT()
# DESCRIPTION:
#   Graceful reboot by turning vm off and on again
GRACEFUL_REBOOT() {
  xl shutdown "$VM_NAME"
  until xl create /etc/xen/"$VM_NAME".cfg; do
    sleep 1
    echo "Waiting for machine to shutdown"
  done
}

# FUNCTION=FORCED_REBOOT()
# DESCRIPTION:
#   Forcibly reboot the virtual machine
FORCED_REBOOT() {
  xl destroy "$VM_NAME"
  START_VM
}

# FUNCTION=REBOOT_VM()
# DESCRIPTION:
#  Attempts to reboot the domU (used in the dom0)
REBOOT_VM() {
  xl reboot "$VM_NAME"
}

# FUNCTION=SSH_REBOOT()
# DESCRIPTION:
#  Attempts to reboot a domU by connecting to it via ssh
#  Port redirecting need to be done in the dom0 
SSH_REBOOT() {
  # using the loopback interface (127.0.0.1)
  # ssh -p 2222 root@localhost "reboot now"
  # rebooting the domU from the dom0
  ssh -p 22 root@172.20.100.178 "reboot now"
}

# FUNCTION=START_VM()
# DESCRIPTION:
#   Attempts to start the vm in the background
#
# GLOBAL VARIABLES:
#   $VM_NAME
#
START_VM(){
  xl create /etc/xen/"$VM_NAME".cfg
  # takes a few seconds for the status to be updated (in xl list)
}

# FUNCTION=CREATE_VM()
# DESCRIPTION:
# # CHANGE IP ADDRESS
# hostname - VM name;
# ip - IP address for communication with the VM;
# netmask - network mask, adapt it according to the server machine's netmask (/22);
# gateway - IP address of the router;
# vcpus - number of processor cores used by the vm;
# memory - amount of RAM that the VM will use;
# size - size of the system image that will be created;
# dist - linux distribution to be installed on the VM, in this case Debian 12 (bookworm);
# password - password to access the virtualized system;
# arch - system architecture;
# bridge - in order for the VM to communicate via the network with the host machine,
# it must have its own network interface connected as a bridge.
# lvm=vg0 - creates two new logical volumes within vg0 for the xenDebian vm: one for the root disk and another for the swap device
CREATE_VM() {
    local memory=512M
    local size=5G
    local ip=172.20.100.178
    local netmask="255.255.252.0" #/22
    local gateway 
    local vcpus=2
    local password=12345678
    
    gateway=$(ip route | awk '/default via/ {print $3}')

    xen-create-image \
    --hostname "$VM_NAME" \
    --ip "$ip" \ 
    --netmask "$netmask" \
    --gateway "$gateway" \
    --bridge=xenbr0 \
    --vcpus "$vcpus" \
    --memory "$memory" \
    --size "$size" \
    --dist bookworm \
    --password "$password" \
    --arch=amd64 \
    --lvm=vg0 \ 
    --role=editor \
    --finalrole=install-nginx
}

# FUNCTION=CREATING_DOMU_ROLES()
# DESCRIPTION:
#  Attempts to fix the problem of distinct network interface names upon the creation of the domU
#  Modifies the ssh config file of the domU to allow password login 
#  Installs the nginx server on the domU
CREATING_DOMU_ROLES(){
  local sed_directory="/etc/xen-tools/sed.d"
  local role_directory="/etc/xen-tools/role.d/"
  local interfaces_sed="$sed_directory/etc/network/interfaces.sed"
  local ssh_sed="$sed_directory/etc/ssh/sshd_config.sed"

  echo "Creating DomU roles..."

  # Step 1: Create the sed.d directory if it doesn't exist
  if [ ! -d "$sed_directory" ]; then
    mkdir -p "$sed_directory"
  fi

  # Step 2: Create the interfaces.sed file inside the sed.d directory
  if [ ! -d "$(dirname "$interfaces_sed")" ]; then
  mkdir -p "$(dirname "$interfaces_sed")"
  fi
  cat <<EOF > "$interfaces_sed"
#!/bin/sed -f

# Replace the interface name eth0 with enX0
s/auto eth0/auto enX0/
s/iface eth0 inet static/iface enX0 inet static/
EOF

  # Step 3: Create sshd_config.sed file inside the sed.d directory
  if [ ! -d "$(dirname "$ssh_sed")" ]; then
  mkdir -p "$(dirname "$ssh_sed")"
  fi
  cat <<EOF > "$ssh_sed"
#!/bin/sed -f
# Permit root login
s/^#PermitRootLogin.*/PermitRootLogin yes/
EOF

  # Step 4: Update the role script to apply sed scripts 
  cat <<EOF > "${role_directory}/editor"
#!/bin/sh
#
# Role-script for generalised editing of files for guests.
# This script works via a skeleton directory containing small .sed files
# which will contain edits to be applied to an arbitrary tree of files upon
# the new domU.
#
# For example, if we have the following sed file:
# /etc/xen-tools/sed.d/etc/network/interfaces.sed
# this will be applied to /etc/network/interfaces upon the new guest if it exists.
# If the file encoded in the name doesn't exist then it will be ignored.
#
# Steve
# --

# Source common functions if available for installing a Debian package
if [ -e /usr/share/xen-tools/common.sh ]; then
    . /usr/share/xen-tools/common.sh
else
    echo "Installation problem"
fi

# Define the installation directory and the prefix for finding scripts
prefix="\$1"
source="/etc/xen-tools/sed.d/"

# Log the start of the script
logMessage "Script \$0 starting"

# Check if the source directory exists
if [ ! -d "\${source}" ]; then
    logMessage "Source directory \${source} not found"
    exit
fi

# Now find files which exist.
for sed_script in \$(find "\${source}" -name '*.sed' -print); do
    # Get the name of the file, minus the source prefix
    file="\${sed_script#\${source}}"

    # Strip the .sed suffix
    file=\$(echo "\$file" | sed -e 's/\.sed\$//')

    # Check if the file exists in the new install
    if [ -e "\${prefix}/\$file" ]; then
        # Log the execution of the script
        logMessage "Running script \$sed_script - against \${prefix}/\$file"

        # Apply the sed script to the corresponding file in the new install
        sed -i~ -f "\$sed_script" "\${prefix}/\$file"
    fi
done

# Log the finish of the script
logMessage "Script \$0 finished"
EOF

  # Step 5: Install and bring up Nginx in the DomU
  cat <<EOF > "$role_directory/install-nginx" # Create new role script 
#!/bin/sh
#
# Role-script for installing Nginx upon the new guest system.
#

# Assign the prefix variable representing the root directory of the guest system
prefix="\$1"

# Source common functions if available for installing a Debian package
if [ -e /usr/share/xen-tools/common.sh ]; then
    . /usr/share/xen-tools/common.sh
else
    echo "Installation problem"
fi

# Log the start of the script
logMessage "Script \$0 starting"

# Install Nginx package
installDebianPackage "\${prefix}" nginx

#  Make sure the Nginx server isn't running, this will cause our
# unmounting of the disk image to fail..

chroot "\${prefix}" /etc/init.d/nginx stop

#  Copy nginx update.conf & defaults from Dom0
cp /etc/nginx/update.conf "\${prefix}/etc/nginx/"
cp /etc/default/nginx "\${prefix}/etc/default/"

#  Log our finish
logMessage "Script \$0 finished"
EOF
  # Set permissions for the role scripts
  chmod +x "$role_directory/editor" "$role_directory/install-nginx"
}

# FUNCTION=CREATE_DISKS()
# DESCRIPTION:
#   Creates disks in the virtual machine from the given quantity and size
#
# PARAMETERS:
#   $1 = disks_quantity --> set in 'virtualizer_functions/xen/setup.sh' as 50
#   $2 = disk_size --> set in 'virtualizer_functions/xen/setup.sh' as 1024
#
# LVM COMMANDS:
#  lvcreate - creates a Logical Volume in an existing Volume Group
#  Firstly, the -L flag is used to specify the size of the volume. Secondly, the -n flag is used to specify a name for the logical volume.
#  Finally the name of the Volume Group to which the logical volume is to belong (and from which the space is to be acquired) is specified.
CREATE_DISKS() {
  local count=1
  local disks_quantity="$1"
  local disk_size="$2"
  local volume_group="vg0"  

  while [[ "$count" -le "$disks_quantity" ]]; do
    lvcreate -L "${disk_size}MB" -n disk$count "$volume_group"
    ((count++))
  done
}

# FUNCTION=REMOVE_DISKS()
# DESCRIPTION:
#   Attempts to remove all disks from the virtual machine, except the VM's swap and disk volumes
#
# LVM COMMANDS:
# lvremove - removes a Logical Volume.
REMOVE_DISKS() {
  local volume_group="vg0"
  local disks_list=$(lvdisplay | grep "LV Path" | grep "$volume_group"| grep -vE "${VM_NAME}-swap|${VM_NAME}-disk" | awk '{print $3}')

  if [ -z "$disks_list" ]; then
    echo "No disks found in volume group $volume_group."
    return
  fi

  for disk in $disks_list; do
    lvremove -f "$disk" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
      echo "Disk $disk removed successfully."
    else
      echo "Error: Failed to remove $disk."
    fi
  done
}

# FUNCTION=ATTACH_DISK()
# DESCRIPTION:
#   Attaches disks to a Xen domU 
#   https://www.systutorials.com/how-to-dynamically-attach-a-disk-to-running-domu-in-xen/
#  
# xl [-v] block-attach <Domain> <BackDev> <FrontDev> 
# [<Mode>] [BackDomain] 
#
# GLOBAL VARIABLES:
#   $VM_NAME
#
# PARAMETERS:
#   $1 = disk_path  -->  set in xen_workload.sh
#   $2 = frotend_name  --> set in xen_workload.sh
#
# USAGE:
#   In the workload script for xen (xen_workload.sh):
#       source ./virtualizer_functions/xen_functions.sh
#       ATTACH_DISK "${disk_path}${count_disks}" "$frontend_name"   
ATTACH_DISK() {
  local disk_path="$1"
  local frontend_name="$2"

  if xl block-attach "$VM_NAME" phy:"$disk_path" "$frontend_name" w; then
    echo "Disk attached successfully: $disk_path -> $frontend_name"
  else
    echo "Failed to attach disk: $disk_path"
  fi
}

# FUNCTION=DETACH_DISK()
# DESCRIPTION:
#   Dettaches disks from virtual machine
#
# GLOBAL VARIABLES:
#   $VM_NAME
#
DETACH_DISK() {
  local frontend_name="$1"

  if xl block-detach "$VM_NAME" "$frontend_name"; then
    echo "Disk detached successfully: $frontend_name"
  else
    echo "Failed to detach disk: $frontend_name"
  fi
}