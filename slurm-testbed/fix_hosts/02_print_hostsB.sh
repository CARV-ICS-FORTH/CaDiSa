
mecho(){
	echo
	echo $1
	echo
}

min_container_to_gen="200"
max_container_to_gen="295"
node=slnode

# step: Printing container IPs:
mecho "Printing container IPs. This list should be pasted in /etc/hosts of host."
lxc-ls -f | grep slnode | awk '{print $5" "$1}'

mecho "Printing container IPs to required_files/etc_hosts file"
lxc-ls -f | grep slnode[0-9]+* | awk '{print $5" "$1}'> ./required_files/etc_hostsB

