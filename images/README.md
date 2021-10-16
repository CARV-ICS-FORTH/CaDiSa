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



If you did not specify `--install $PWD/install` `--build $PWD/build` or `--results $PWD/results` then you can run with the built in versions of these programs.

## Development environment details

In this container there is a hierarchy for HPC tools at /opt/hpc
The three mountable folders have symbolinc links at the following locations inside that hierarchy:
* /opt/mounts/build   -> /opt/hpc/local/build
* /opt/mounts/install -> /opt/hpc/external
* /opt/mounts/results -> /opt/hpc/results
