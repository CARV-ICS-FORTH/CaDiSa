
mecho(){
	echo
	echo $1
	echo
}

min_container_to_gen="000"
max_container_to_gen="127"
node=slnode

mecho "Copying etc_hosts inside each container"
for ext in $(eval echo "{$min_container_to_gen..$max_container_to_gen}"); do
	newnode=$node$ext
	cat ./required_files/etc_hosts_header > /var/lib/lxc/$newnode/rootfs/etc/hosts
	cat ./required_files/etc_hostsA >>  /var/lib/lxc/$newnode/rootfs/etc/hosts
	cat ./required_files/etc_hostsB >>  /var/lib/lxc/$newnode/rootfs/etc/hosts
done

