#! /bin/bash

target_type="url"
target="https://www.spamhaus.org/drop/edrop.lasso"
ipset_params="hash:net"

#filename=$(basename ${target})
filename=Spamhaus_EDROP.lasso
firewall_ipset=${filename%.*}			# ipset will be filename minus ext
#data_dir="/var/db/${firewall_ipset}"	# data directory will be same
data_dir="/var/db/Block_Lists"			# data directory
data_file="${data_dir}/${filename}"
ipset_dir="/etc/sysconfig/ipset.d"		# directory where ipsets are saved to and restored from

DIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/Block_Lists_Main.sh"

main $@
