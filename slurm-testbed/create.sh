#!/bin/bash

# SLURM containers generator
# FORTH

mecho(){
    echo 
    echo $1
    echo 
}

node=slnode


# config: Use 3 digits e.g: 008, 009 or 099, containers start with 000
min_container_to_gen="000"
max_container_to_gen="127"

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  exit
fi


apt-get install lxc lxc-templates

cp -i ./required_files/archive-key.gpg /var/cache/lxc/debian/

# Required on the host in order to start many containers
echo '8192' > /proc/sys/fs/inotify/max_user_instances

#mecho "Destroying old containers"
#./destroy.sh

# step: Create new container
mecho "Creating new container"
lxc-create -n $node -t debian -- -r bullseye
#lxc-create -n $node -t debian -- -r bookworm
#lxc-create -n $node -t ubuntu

# step: Start lxc node
mecho "Starting container"
lxc-start $node

sleep 5

# step: List container details
mecho "Listing container details"
lxc-info $node

# step: Install software in container
mecho "Installing software in the container"
lxc-attach -n $node -- /bin/bash -c "apt-get update"
lxc-attach -n $node -- /bin/bash -c "apt-get install -y exuberant-ctags liblz4-dev lz4 hwloc pkg-config vim gcc g++ make automake autoconf htop python3"
lxc-attach -n $node -- /bin/bash -c "apt-get install -y cgroup-tools libtool rsync git libevent-dev flex libyaml-cpp-dev"
lxc-attach -n $node -- /bin/bash -c "apt-get install -y iputils-ping tree strace valgrind libdbus-1-dev libhttp-parser-dev libpam0g-dev libjsonparser-dev dbus numactl libnuma-dev htop libmunge-dev munge sudo zlib1g-dev curl"
lxc-attach -n $node -- /bin/bash -c "apt-get dist-upgrade -y"


# step: Create a user
mecho "Attempting to create new user: ppetrak"
lxc-attach -n $node -- /bin/bash -c "useradd -m ppetrak" 
lxc-attach -n $node -- /bin/bash -c "chsh ppetrak -s /bin/bash"

# step: Add user to sudoers
mecho "Add user to sudoers"
lxc-attach -n $node -- /bin/bash -c "adduser ppetrak sudo"
mecho "Stop using password for sudo"
lxc-attach -n $node -- /bin/bash -c "echo \"ppetrak     ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/ppetrak"

# step: Create .ssh dir and adjust permissions
mecho "Create .ssh dir and adjust permissions"

lxc-attach -n $node -- /bin/bash -c "mkdir -p /home/ppetrak/.ssh"
lxc-attach -n $node -- /bin/bash -c "chmod 700 /home/ppetrak/.ssh"
lxc-attach -n $node -- /bin/bash -c "ls -ld /home/ppetrak/.ssh"

# step: Push ssh keys inside the container
mecho "Copying ssh keys and config inside the container"
cp ./required_files/id_rsa_docker.pub /var/lib/lxc/$node/rootfs/home/ppetrak/.ssh/id_rsa.pub
cp ./required_files/id_rsa_docker /var/lib/lxc/$node/rootfs/home/ppetrak/.ssh/id_rsa
cp ./required_files/ssh_config_for_containers /var/lib/lxc/$node/rootfs/home/ppetrak/.ssh/config

lxc-attach -n $node -- /bin/bash -c "ls /home/ppetrak/.ssh/"

# step: Add public key to authorized keys
mecho "Add public key to authorized keys"
cat /var/lib/lxc/$node/rootfs/home/ppetrak/.ssh/id_rsa.pub > /var/lib/lxc/$node/rootfs/home/ppetrak/.ssh/authorized_keys
cat /var/lib/lxc/$node/rootfs/home/ppetrak/.ssh/authorized_keys

# step: Adjusting .ssh dir ownership
mecho "Adjusting .ssh dir ownership"
lxc-attach -n $node -- /bin/bash -c "chown -R ppetrak:ppetrak /home/ppetrak/.ssh"


# step: Copy bashrc and vimrc files
mecho "Copy bashrc and vimrc files for user and root"
cp required_files/user_bashrc /var/lib/lxc/$node/rootfs/home/ppetrak/.bashrc
cp required_files/vimrc /var/lib/lxc/$node/rootfs/home/ppetrak/.vimrc
#
cp required_files/user_bashrc /var/lib/lxc/$node/rootfs/root/.bashrc
cp required_files/vimrc /var/lib/lxc/$node/rootfs/root/.vimrc

# step: Add slurmd service file
mecho "Add slurmd service file"
cp required_files/slurmd.service /var/lib/lxc/$node/rootfs/etc/systemd/system/

# step: Enable slurmd service
mecho "Enable slurmd service"
lxc-attach -n $node -- /bin/bash -c "systemctl enable slurmd"

# step: Add common host mount point
mecho "Mount external /opt/sw"
if grep "mount" /var/lib/lxc/$node/config > /dev/null
then
	echo "lxc.mount.entry already set in lxc config."
else
	echo "lxc.mount.entry = /archive/users/ppetrak/slurm_containers_sw/ opt/sw/ none bind,create=dir 0 0" >> /var/lib/lxc/$node/config
fi

#exit
##################### FINISHED CONTAINER SETUP ############


# step: Copying the container to multiple copies
mecho "Generating container multiple copies"
lxc-stop $node
for ext in $(eval echo "{$min_container_to_gen..$max_container_to_gen}"); do
    newnode=$node$ext
    lxc-copy -n $node -N $newnode
    mecho "Generated new node:"
    lxc-info $newnode
    sleep 2
done

# step: Starting the newly generated nodes
mecho "Starting the newly generated nodes"
for ext in $(eval echo "{$min_container_to_gen..$max_container_to_gen}"); do
    newnode=$node$ext
    lxc-start $newnode
    #lxc-info $newnode
    #mecho ""
    sleep 1
done

mecho "Waiting for containers and network to start"
sleep 24

# step: Restarting initial parent node
mecho "Restarting initial parent node"
lxc-stop $node
lxc-start $node

# step: Printing container IPs:
mecho "Printing container IPs. This list should be pasted in /etc/hosts of host."
#lxc-ls -f | grep slnode[0-9]+* | awk '{print $5" "$1}'
lxc-ls -f | grep slnode | awk '{print $5" "$1}'

mecho "Printing container IPs to required_files/etc_hosts file"
lxc-ls -f | grep slnode[0-9]+* | awk '{print $5" "$1}'> ./required_files/etc_hosts


#mecho "Copying etc_hosts inside each container"
#for ext in $(eval echo "{$min_container_to_gen..$max_container_to_gen}"); do
#newnode=$node$ext
#    cat ./required_files/etc_hosts >>  /var/lib/lxc/$newnode/rootfs/etc/hosts
#done


#mecho "Destroying the newly generated nodes"
#for ext in $(eval echo "{$min_container_to_gen..$max_container_to_gen}"); do
#    newnode=$node$ext
#    lxc-stop $newnode
#    lxc-destroy $newnode
#done
#
mecho "Script finished"

