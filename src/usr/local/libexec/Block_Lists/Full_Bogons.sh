#!/bin/bash

# All parameters $@ are passed to main function (Block_List_Main.sh).
command=$1		# Commands: restore, unload, load, update
ip_version=$2	# IP Versions: IPv4 (case sensitive) or empty

if [ "$ip_version" == "IPv4" ] || [ "$ip_version" == "" ]; then
	target_type="url"
	target="https://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt"
	ipset_params="hash:net maxelem 4096"

	#filename=$(basename ${target})
	filename=Full_Bogons_IPv4.txt
	firewall_ipset=${filename%.*}			# ipset will be filename minus ext
	#data_dir="/var/db/${firewall_ipset}"	# data directory will be same
	data_dir="/var/db/Block_Lists"			# data directory
	data_file="${data_dir}/${filename}"
	ipset_dir="/etc/sysconfig/ipset.d"		# directory where ipsets are saved to and restored from
fi

if [ "$ip_version" == "IPv6" ]; then
	target_type="url"
	target="https://www.team-cymru.org/Services/Bogons/fullbogons-ipv6.txt"
	ipset_params="hash:net family inet6 maxelem 131072"

	#filename=$(basename ${target})
	filename=Full_Bogons_IPv6.txt
	firewall_ipset=${filename%.*}			# ipset will be filename minus ext
	#data_dir="/var/db/${firewall_ipset}"	# data directory will be same
	data_dir="/var/db/Block_Lists"			# data directory
	data_file="${data_dir}/${filename}"
	ipset_dir="/etc/sysconfig/ipset.d"		# directory where ipsets are saved to and restored from
fi

DIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/Block_Lists_Main.sh"

main $@
