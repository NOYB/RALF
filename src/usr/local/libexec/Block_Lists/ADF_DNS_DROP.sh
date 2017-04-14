#!/bin/bash

target_type="file"
#target="/var/named/data/ADF/*.ADF_IP_Addresses_DROP"
target="/var/log/ADF/BIND/ADF.IP_Addresses.BIND.DROP"
ipset_params="hash:net"

#filename=$(basename ${target})
filename=ADF_DNS_DROP.txt
firewall_ipset=${filename%.*}			# ipset will be filename minus ext
#data_dir="/var/db/${firewall_ipset}"	# data directory will be same
data_dir="/var/db/Block_Lists"			# data directory
data_file="${data_dir}/${filename}"
ipset_dir="/etc/sysconfig/ipset.d"		# directory where ipsets are saved to and restored from

DIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/Block_Lists_Main.sh"

main $@
