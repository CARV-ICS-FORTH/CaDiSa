# SLURM-testbed
How-to describing setup of container-based SLURM testbed for exploration
of performance overheads at scale.


## Introduction

This guide will help you to setup a number of LXC containers on two hosts (or more) and interconnect them all together in the same network,
in order to simulate a large Slurm enabled cluster.

In our test environment we have tested with 2 hosts and 224 nodes in total: 
- host-A with 128 containers
- host-B with 96 containers


## Setup

For setting up the containers we are going to use a single script: `create.sh`.

For the communication of the containers a keypair of SSH keys is required. Therefore,
you need to generate an SSH key pair (public, private) and add them in folder `required_files`. 
The names expected by the script are: `id_rsa_docker` and `id_rsa_docker.pub`.

In order to generate the LXC containers you need to run (as root) the `create.sh` script on each of the hosts.
Adjust the `min_container_to_gen` and `max_container_to_gen` variables, before running.
For example to generate containers `slnode000` to `slnode127`, for host-A (128 nodes), one needs to set:
```
min_container_to_gen="000"
max_container_to_gen="127"
```
One needs to have `lxc` and `lxc-templates` installed on the host systems. Additionally,
one has to adjust the `/proc/sys/fs/inotify/max_user_instances` to a high value e.g. `8192`,
in order to be able to start several containers.

The script `create.sh` will start by downloading a debian bullseye image, and start
a parent container named `slnode`. Then it will install a number of required packages 
inside that container.

Then it will create a user (`ppetrak`) in the new container, and setup the user's
`.ssh` directory. The aforementioned ssh keypair will be copied inside `.ssh` directory.
Additionally, the public key will be added to the authorized keys, for passwordless login,
among the containers.

As a next step, the user's `.vimrc` and `.bashrc` files will be copied inside the 
container from templates found in `required_files` folder.

Next, a slurmd service file will be copied inside the container, and slurmd service
will be enabled, so that it autostarts once the container starts. This service file
uses the path: `/opt/sw/apps/slurm-22.05.0/sbin/slurmd -D -s $SLURMD_OPTIONS`.
Adjust this path according to your slurm installation.

As a next step an external path (where slurm and other software can be placed) is 
mounted on the container. More specifically `/archive/users/ppetrak/slurm_containers_sw/`
is mounted in `opt/sw/`.
```
echo "lxc.mount.entry = /archive/users/ppetrak/slurm_containers_sw/ opt/sw/ none bind,create=dir 0 0" >> /var/lib/lxc/$node/config
```

`WARNING:` Note the missing `/` from the mount point path (`opt/sw/`).

At this point the container `slnode` is considered finalized, and is copied to create containers `slnode000` to `slnode127`.
Once the containers are created, they are started, and their assigned IPs are printed by the script. 

In order to be able to resolve each container hostname to an IP, the `/etc/hosts` file, in each container should be adjusted appropriately.
You are advised to first run `create.sh` in both `host-A` and `host-B`, and then adjust the `/etc/hosts` of each container, so that it 
contains the hostname and IP of every container. Four scripts are provided in folder `fix_hosts`, in order to help you automate this process. 
Run them in order `01,02,03,04`, to set the `/etc/hosts` in all containers.

For proper MPI and SLURM communication between all containers, the munge key `/etc/munge/munge.key` should be the same in all containers.
An example `munge.key` can be found in `required_files` directory.

For `host-A`, we consider the subnet `10.0.3.0/24`, and `10.0.3.1` for bridge `lxcbr0`.
For `host-B`, we consider the subnet `10.0.4.0/24`, and `10.0.4.1` for bridge `lxbr0`.

In order to make the containers of `host-A` visible to `host-B` and vice versa, one has to run:
```
hostB: ip route add 10.0.3.0/24 via <host-A IP>
hostA: ip route add 10.0.4.0/24 via <host-B IP>
```

Additionally, for MPI and SLURM to work properly, one has to remove any `MASQUERADE` rules from the IP tables of the two hosts.
For example (suppose `host-A` has IP `192.168.122.x`):
```
iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p tcp --sport 1024:65535 -j MASQUERADE
iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p udp --sport 1024:65535 -j MASQUERADE
iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
```


