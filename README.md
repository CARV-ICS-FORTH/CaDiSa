# CaDiSa aka CARV Distributed Sandbox

## Acknowledgements

This work was derived from [PMIx Docker Swarm Toy Box by Josh Hursey](https://github.com/jjhursey/pmix-swarm-toy-box).


## Purpose

This software is a collection of scripts and docker images used to deploy containers over one or multiple physical hosts for developing distributed software. It uses docker to build containers and and docker swarm to create an overlay network to connect these containers together in order to simulate a cluster. The initial use was for developing and testing OpenMPI and PMIx.

Naming conventions:
* physical hosts == hosts
* created containers == nodes

## Prerequisites

* Docker Engine must be installed on all hosts. (https://docs.docker.com/engine/install/)
* Docker group must be created on all hosts and the user who runs CaDiSa must be a member on docker group in each host.
* If you want to run on multiple hosts, the location from where you run CaDiSa must be a shared location between all hosts eg NFS 

## Installation

### Single host setup
Initialize docker swarm

```
docker swarm init
```

### Multiple hosts setup
Chose one of the hosts to act as a manager for docker swarm. Then initialise docker swarm on it as a manager.

```
docker swarm init --advertise-addr [MAN_IP_ADDRESS]
```
Where [MAN_IP-ADDRESS] is the address of the physical network of the manager host that you want the container traffic to pass through.
After initialisation a unique [TOKEN] will be returned. It is used to connect other hosts to this swarm manager.

Then from all other hosts join this swarm

```
docker swarm join     --advertise-addr [WORKER_IP_ADDRESS] --token [TOKEN]     [MAN_IP_ADDRESS]:2377
```
Where [WORKER_IP_ADDRESS] is the ip address of each worker host that is on the same network with the manager host. After this is done on EACH host, all inidvidual docker engines on all hosts can communicate through the nework.

More info on swarm commands
[docker swarm init](https://docs.docker.com/engine/reference/commandline/swarm_init/)
[docker swarm join](https://docs.docker.com/engine/reference/commandline/swarm_join/)

## Build the images

You can use whichever image you want for the nodes. However, if you want to use multiple hosts, make sure the image is accessible from all hosts. To build the images supplied with this tool execute:
```
./build-images.sh
```

Example:
```
shell$ ./build-images.sh
Sending build context to Docker daemon 24.63 MB
Step 1/46 : FROM centos:7
 ---> eeb6ee3f44bd
Step 2/46 : MAINTAINER Theocharis Vavouris <vavouris@ics.forth.gr>
...
Step 46/46 : CMD /usr/sbin/sshd -D
 ---> Running in c3a08714b831
 ---> 2b933888700b
Removing intermediate container c3a08714b831
Successfully built 2b933888700b

```
## Mount external directories on nodes

For software development, CaDiSa has the option to mount external directories which are shared between nodes to speedup compilation and instalation of software under development. The locations on each node where external directories are mounted are:

```
/opt/mounts/build
/opt/mounts/install
/opt/mounts/results
```
The first two are for building and installing the software, and the third is used to collect results from nodes to be studied later.
When using multiple hosts setup, these external directories must be in a shared location between hosts eg NFS. 

## Startup the cluster

We use start-cadisa.sh. When we have multiple hosts, this must run from swarm management host. This script will:
 * Create a private overlay network between the pods (`docker network create --driver overlay --attachable`)
 * Start N containers each named `$USER-nodeXY` where XY is the node number startig from `01`.
 
```
./start-cadisa.sh
```

Example:

```
shell$ ./start-cadisa.sh --help
Usage: start-cadisa.sh [option]
    -m | --multiple HOST1,HOST2,...,HOSTN distribute the nodes over multiple physical hosts (DOCKER SWARM HAS TO BE CONFIGURED FIRST!)
    -p | --prefix PREFIX       Prefix string for hostnames (Default: vavouris-)
    -n | --num NUM             Number of nodes to start on this host (Default: 2)
    -i | --image NAME          Name of the container image (Required)
         --build DIR           Full path to the 'build' directory
         --install DIR         Full path to the 'install' directory
         --results DIR         Full path to the 'results' directory
    -d | --dryrun              Dry run. Do not actually start anything.
    -h | --help                Print this help message
shell$ ./start-cadisa.sh -n 5
Establish network: cadisa-net
Starting: vavouris-node01
Starting: vavouris-node02
Starting: vavouris-node03
Starting: vavouris-node04
Starting: vavouris-node05
```


## Drop into the first node

We use a script to drop in on the first node in order not to use docker commands. If we used a custom prefix for hostnames when starting CaDiSa, we should pass that prefix as an argument to the script.
```
./drop-in.sh 
```

### To start with the external/developer versions of OpenPMIx/PRRTE/Open MPI 

```
./start-cadisa.sh --install $PWD/install --build $PWD/build --results $PWD/results
```

Example:

```
shell$ ./start-cadisa.sh -n 5 --install $PWD/install --build $PWD/build --results $PWD/results
Establish network: cadisa-net
Starting: vavouris-node01
Starting: vavouris-node02
Starting: vavouris-node03
Starting: vavouris-node04
Starting: vavouris-node05
```



If you did not specify `--install $PWD/install --build $PWD/build` then you can run with the built in versions.

## Setup your development environment outside the container

The container is self contained with all of the necessary software to build/run OpenPMIx/PRRTE/Open MPI from what was built inside.
However, for a developer you often want to use your version of these builds and use the editor from the host system.

We will use volume mounts to make a developer workflow function by overwriting the in-container version with the outside-container version of the files. We are using the local disk as a shared file system between the virtual nodes.

The key to making this work is that you can edit the source code outside of the container, but all builds must occur inside the container. This is because the relative paths to dependent libraries and install directories are relative to the paths inside the container's file system not the host file system.

Note that this will work when using Docker Swarm on a single machine. More work is needed if you are running across multiple physical machines.


### Checkout your version of OpenPMIx/PRRTE/Open MPI

For ease of use I'll checkout into a `build` subdirectory within this directory (`$TOPDIR` is the same locaiton as this `README.md` file), but these source directories can be located anywhere on your system as long as they are in the same directory. We will mount this directory over the top of `/opt/hpc/build` inside the container. The sub-directory names for the git checkouts can be whatever you want - we will just use the defaults for the examples here.

Setup the build directory.

```
cd $TOPDIR
mkdir -p build
cd build
```

Check out your OpenPMIx development branch (on your local file system, outside the container).

```
git clone git@github.com:openpmix/openpmix.git
```

Check out your PRRTE development branch (on your local file system, outside the container).

```
git clone git@github.com:openpmix/prrte.git
```

Check out your Open MPI development branch (on your local file system, outside the container).
Note: You can skip the Open MPI parts if you do not intend to use it

```
git clone git@github.com:open-mpi/ompi.git
```


### Create an install directory for OpenPMIx/PRRTE/Open MPI

This directory will serve as the shared install file system for the builds. We will mount this directory over the top of `/opt/hpc/external` inside the container. The container's environment is setup to look for these installs at specific paths so though you can build with whatever options your want, the `--prefix` shouldn't be changed:
 * OpenPMIx: `--prefix /opt/hpc/external/pmix`
 * PRRTE: `--prefix /opt/hpc/external/prrte`
 * Open MPI: `--prefix /opt/hpc/external/ompi`

```
cd $TOPDIR
mkdir -p install
```

For now it will be empty. We will fill it in with the build once we have the cluster started.




## (Developer) Verify the volume mounts

if you did specify `--install $PWD/install --build $PWD/build` then you can verify that the volumes were mounted in as the `mpiuser` in `/opt/hpc` directory.
 * Source/Build directory: `/opt/hpc/build`
 * Install directory: `/opt/hpc/external`

```
shell$ ./drop-in.sh 
[mpiuser@jhursey-node01 ~]$ whoami
mpiuser
[mpiuser@jhursey-node01 ~]$ ls -la /opt/hpc/
total 20
drwxr-xr-x 1 root    root    4096 Dec 21 14:54 .
drwxr-xr-x 1 root    root    4096 Dec 21 14:10 ..
drwxr-xr-x 8 mpiuser mpiuser  256 Dec 21 14:58 build
drwxrwxrwx 1 root    root    4096 Dec 21 14:54 etc
drwxrwxrwx 1 root    root    4096 Dec 21 14:25 examples
drwxr-xr-x 3 mpiuser mpiuser   96 Dec 21 14:59 external
drwxr-xr-x 1 root    root    4096 Dec 21 14:25 local
[mpiuser@jhursey-node01 ~]$ ls -la /opt/hpc/build/   
total 16
drwxr-xr-x  8 mpiuser mpiuser  256 Dec 21 14:58 .
drwxr-xr-x  1 root    root    4096 Dec 21 14:54 ..
drwxr-xr-x 27 mpiuser mpiuser  864 Dec 21 14:34 ompi
drwxr-xr-x 37 mpiuser mpiuser 1184 Dec 21 14:59 openpmix
drwxr-xr-x 22 mpiuser mpiuser  704 Dec 21 14:34 prrte
```

## Compile your code inside the first node

Edit your code on the host file system as normal. The changes to the files are immediately reflected inside all of the swarm containers.

When you are ready to compile drop into the container, change to the source directory, and build as normal.

Note: I created build scripts for OpenPMIx/PRRTE/Open MPI in `$TOPDIR/bin` that you can use. Just copy them into the `build` directory so they are visible inside the container.

```
shell$ cp -R bin build/
shell$ ./drop-in.sh 
[mpiuser@jhursey-node01 ~]$ whoami
mpiuser
[mpiuser@jhursey-node01 ~]$ cd /opt/hpc/build/openpmix
[mpiuser@jhursey-node01 openpmix]$ ../bin/build-openpmix.sh 
...
[mpiuser@jhursey-node01 openpmix]$ ../bin/build-prrte.sh 
...
```

The build and install directories are preserved on the host file system so you do not necessarily need to do a full rebuild everytime - just the first time.


## Run your code inside the first node

```
shell$ ./drop-in.sh 
[mpiuser@jhursey-node01 ~]$ whoami
mpiuser
[mpiuser@jhursey-node01 /]$ env | grep MCA
PRRTE_MCA_prrte_default_hostfile=/opt/hpc/etc/hostfile.txt
[mpiuser@jhursey-node01 build]$ mpirun -npernode 2 hostname
[jhursey-node01:94589] FINAL CMD: prte &
jhursey-node01
jhursey-node01
jhursey-node04
jhursey-node04
jhursey-node03
jhursey-node03
jhursey-node05
jhursey-node05
jhursey-node02
jhursey-node02
TERMINATING DVM...DONE
```

## Shutdown the cluster

The script (above) creates a shutdown file that can be used to cleanup when you are done.

```
./tmp/shutdown-*.sh 
```
