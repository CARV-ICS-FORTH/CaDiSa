# CaDiSa aka CARV Distributed Sandbox

## Acknowledgements

This work was derived from [PMIx Docker Swarm Toy Box by Josh Hursey](https://github.com/jjhursey/pmix-swarm-toy-box).

We thankfully acknowledge the support of the European Commission and the Greek General Secretariat for Research and Innovation under the EuroHPC Programme through project DEEP-SEA (GA-955606). National contributions from the involved state members (including the Greek General Secretariat for Research and Innovation) match the EuroHPC funding.


## Versions

Please select the version you want to use by using "git checkout" command to change branch after clone.
* Branch V1.0:initial Version
* Master: Added cpu/ram limit per container. Untested 


## Purpose

This software is a collection of scripts and docker images used to deploy containers over one or multiple physical hosts for developing distributed software. It uses docker to build containers and and docker swarm to create an overlay network to connect these containers together in order to simulate a cluster. The initial use was for developing and testing OpenMPI and PMIx.

Naming conventions:
* physical hosts == hosts
* created containers == nodes

This is the general contents layout:
* ./bin: folder hierarchy that has scripts that usefull scripts and program that can be copied inside a node
* ./images: folder hierarchy that contains docker image files that are uesd to build docker images
* ./src: folder hierarchy that contain source files that are copied into an image when it is being built
* ./tests: folder hierarchy that contain test files that are copied into an image when it is being built
* ./tmp: folder that contains the hostfile and shutdown script for CaDiSa nodes. start-cadisa.sh creates these files
* ./build_images.sh: script that builds the docker images
* ./drop-in.sh: script that is used to access the first CaDiSa node
* ./start-cadisa.sh: scripts that starts CaDiSa and sets up the nodes

## Prerequisites

* SSH with SSH keys properly set up for seamless SSH connections between the hosts without the use of passwords.
* Docker Engine must be installed on all hosts. (https://docs.docker.com/engine/install/)
* Docker group must be created on all hosts and the user who runs CaDiSa must be a member on docker group in each host.
* If you want to run on multiple hosts, the location from where you run CaDiSa must be a shared location between all hosts eg NFS and make sure the local root users can have access to this shared folder, because docker runs with superuser privileges.

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

## CARV Cluster Setup (READ SUPER IMPORTANT)

We've installed Docker and setup a swarm inside CARV Cluster. It consists of sith type machines and sith0 is the manager node. Sith1 to sith7 are the worker nodes. CARV Cluster home dirctories are on NFS but for security, we squash root access so local root doesn't have access inside these directories. Therefore we recommend to use /archive which is also shared via NFS, but local root access is permitted. Create a folder with your desired permissions there and inside said folder, clone this repo and run CaDiSa. However, we do not take backups or care about /archive so after one finished his/her work there, one should copy said work to one's home directory. For safety.

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
When using multiple hosts setup, these external directories must be in a shared location between hosts e.g. NFS.

This setup has two advantages:
* You compile the code on one node only and then all the nodes have the compiled software. 
* The developer can write code outside of the node, using his/her own editor/IDE etc.

If one does not use external directories, then prebuilt versions of tested software are inside the containers, for testing/geting familiar with the use of the environment.

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

We use a script to drop in on the first node in order not to use docker commands. If we used a custom prefix for hostnames when starting CaDiSa, we should pass that prefix as an argument to the script. Also, we use the drop-in script on the first host that we have put nodes in if we used -m option when starting CaDiSa. Eg if we did `start-cadisa.sh -n 8 -m sith3,sith4` we should run drop-in.sh on sith3.
```
./drop-in.sh 
```

## Shutdown the cluster

The script ./tmp/shutdown-[HOSTNAME].sh creates a shutdown file that can be used to cleanup when you are done. [HOSTNAME] is the name of the host where we've ran start-cadisa.sh and this should be the host from where this script should run.

```
./tmp/shutdown-tie1.sh 
```

# CREDITS / FUNDING

We thankfully acknowledge the support of the European Commission and the
Greek General Secretariat for Research and Innovation under the EuroHPC
Programme through the DEEP-SEA project (GA 955606). National
contributions from the involved state members (including the Greek
General Secretariat for Research and Innovation) match the EuroHPC
funding.
