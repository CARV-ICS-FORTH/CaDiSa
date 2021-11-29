# CaDiSa docker images

## list of images
* ompi-toybox: Centos7 with all the necessary programs to compile and test openMPI PRRTE and PMIx


# ompi-toybox

## To start with the external/developer versions of OpenPMIx/PRRTE/Open MPI 

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



If you did not specify `--install $PWD/install` `--build $PWD/build` or `--results $PWD/results` then you can run with the built in versions of these programs. For testing/getting familiar with the container.

The built-in versions of these programs are:
- PMIx v3.2
- PRRTE v2.0
- OMPI 4.1.1

Also for convinient testing of openMPI, OSU micro benchmarks version 5.8 is installed on folder /opt/hpc/benchmarks. The GCC v10 is installed.
## Development environment details

In this container there is a hierarchy for HPC tools at /opt/hpc
The three mountable folders have symbolinc links at the following locations inside that hierarchy:
* /opt/mounts/build   -> /opt/hpc/local/build
* /opt/mounts/install -> /opt/hpc/external
* /opt/mounts/results -> /opt/hpc/results

## Caveats/examples
- This image has network for internet access through docker application. This messes up with openMPI network selection process. So when running mpirun always use`--mca btl_tcp_if_exclude 172.18.0.0/16,127.0.0.1/16` option to eclude internet access network and localhost. Then the traffic goes through the networtk that connects the containers together, aka cadisa-net. this is facilitaded through Mellanox 56Gbps RoCE network at CARV-Cluster setup.
More info: https://www.open-mpi.org/faq/?category=tcp#tcp-selection

- For convenience, there is a hostfile with all the nodes' IP adresses at `/opt/hpc/etc/hostfile.txt`. If you use that, you'll have to fine-tune openmpi on how to select nodes. You can use `--map-by node` option so the processes are destributed round-robin per node.
More info: https://www.open-mpi.org/faq/?category=running#mpirun-scheduling

- example running osu_bw on two hosts with hostfile 
```
[cadisa@vavouris-node01 /]$ mpirun -np 2 --hostfile /opt/hpc/etc/hostfile.txt --map-by node --mca btl_tcp_if_exclude 172.18.0.0/16,127.0.0.1/16 $OSU_ROOT/osu-micro-benchmarks/mpi/pt2pt/osu_bw
# OSU MPI Bandwidth Test v5.8
# Size      Bandwidth (MB/s)
1                       0.08
2                       0.16
4                       0.31
8                       0.63
16                      1.27
32                      2.52
64                      5.08
128                    10.10
256                    20.08
512                    39.98
1024                   78.75
2048                  122.71
4096                  216.95
8192                  296.70
16384                 456.37
32768                 619.16
65536                 509.09
131072                566.20
262144                641.23
524288                705.70
1048576               499.13
2097152               491.83
4194304               499.60
```
