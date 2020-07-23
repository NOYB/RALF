#! /bin/bash

# Create and apply the list set (update/load).
create_apply_ipset() {
	# Create the permanent set if it does not exist.
	# Do this at beginning of process to ensure a failure doesn't prevent the set from getting created.  Which could prevent IP Tables from loading.
	ipset create -exist ${firewall_ipset} ${ipset_params}

	if [ ! -r ${data_file} ]; then
		exit
	fi

	# Create a new/temp set and ensure it is empty.
	temp_ipset="${firewall_ipset}_temp"
	ipset create -exist ${temp_ipset} ${ipset_params}
	ipset flush ${temp_ipset}

	# Load the list into the new/temp set.  Ignoring any duplicate entries.
	cat ${data_file} \
	| awk --posix \
	-v IP_RegEx="$IPADDR_2Esc(/$IPCIDR)?" \
	'{ if ($1 ~ IP_RegEx) print ($1) }' \
	| grep -Ev "^192.168.0.0/16|^172.16.0.0/12|^127.0.0.0/8|^10.0.0.0/8|0.0.0.0/8" - \
	| while read network; do
#		ipset add -exist ${temp_ipset} ${network}	# This is very slow (pipe to ipset restore command instead)
		echo 'add '${temp_ipset}' '${network}		# This is about 30x faster (faster even than file redirect)
	  done \
	| ipset restore -exist

	# Activate the new set (swap the temp set with the permanent set).
	ipset swap ${temp_ipset} ${firewall_ipset}
	ipset destroy ${temp_ipset}
}


# Save the ipset.
save_ipset() {
	mkdir -pm 700 ${ipset_dir}
# If SELinux blocks ipset save -file operation when run via systemd; write permission denied.  Use stdout redirection method.
	ipset save -file ${ipset_dir}/${firewall_ipset}.set ${firewall_ipset}
	if [ $? -ne 0 ]; then
		echo "Stdout redirection method used for saving ipset ${firewall_ipset}"
		ipset save > ${ipset_dir}/${firewall_ipset}.set ${firewall_ipset}
	fi
	chmod 600 ${ipset_dir}/${firewall_ipset}.set
}


# Restore the saved ipset.
restore_ipset() {
	# Create the permanent set if it does not exist.
	# Do this at beginning of process to ensure a failure doesn't prevent the set from getting created.  Which could prevent IP Tables from loading.
	ipset create -exist ${firewall_ipset} ${ipset_params}

	# Attempt to restore the ipset from saved ipset file.
	if [ -r ${ipset_dir}/${firewall_ipset}.set ]; then
		ipset flush ${firewall_ipset}
# If SELinux blocks ipset restore -file operation when run via systemd; read permission denied.  Use stdin redirection method.
		ipset restore -exist -file ${ipset_dir}/${firewall_ipset}.set
		if [ $? -ne 0 ]; then
			echo "Stdin redirection method used for restoring ipset ${firewall_ipset}"
			cat ${ipset_dir}/${firewall_ipset}.set | ipset restore -exist
		fi
		RES=$?
	else
		RES=1
	fi

	# If the restore failed then attempt to "load" (create/apply) and save the ipset.
	if [ $RES -ne 0 ]; then
		create_apply_ipset
		save_ipset
	fi
}


get_target() {
	if [ "$target_type" == "file" ]; then
		get_target_file
	fi
	if [ "$target_type" == "url" ]; then
		get_target_url
	fi
}
		
		
get_target_file() {
	# Check if updates have occurred.
	if [ -f ${target} ] && [ -f ${data_file} ]; then
		if [ $(date -r ${target} +%Y%m%d%H%M%S) -le $(date -r ${data_file} +%Y%m%d%H%M%S) ]; then
#			if (cmp -s ${target} ${data_file}); then
				exit
#			fi
		fi
	fi

	# Get the newer target.
	if [ -r ${target} ]; then
		# If the data directory does not exist, create it.
		mkdir -pm 0750 ${data_dir}

		cp -p ${target} ${data_file}.tmp

		# IPv split target into ipv data file
		ipv_split_data_file

		rm -f ${data_file}.tmp

		if [ $split_rc -eq 0 ]; then

			chmod 600 ${data_file}
			create_apply_ipset
			save_ipset

			# Log the file modification time.
			timestamp=$(date -r ${data_file} +%m/%d' '%R)
			logger -p cron.notice "IPSet: ${firewall_ipset} updated (as of: ${timestamp})."
		fi
	fi
}


get_target_url() {
	# If the data directory does not exist, create it.
	mkdir -pm 0750 ${data_dir}

	# Preserve the current file modification time.
	old_timestamp=0
	[ -w ${data_file} ] && old_timestamp=$(date -r ${data_file} +%Y%m%d%H%M%S)

	# Fetch the file only if it's newer than the version we already have.
	#wget -qNP ${data_dir} ${target}
	wget -qN -O ${data_file} ${target}

	if [ $? -ne 0 ]; then
		logger -p cron.err "IPSet: ${firewall_ipset} wget failed."
		exit 1
	fi

	# Check if updates have occurred.
	timestamp=0
	[ -r ${data_file} ] && timestamp=$(date -r ${data_file} +%Y%m%d%H%M%S)
	if [ ${timestamp} -gt ${old_timestamp} ]; then

		chmod 600 ${data_file}
		create_apply_ipset
		save_ipset

		# Log the file modification time.
		timestamp=$(date -r ${data_file} +%m/%d' '%R)
		logger -p cron.notice "IPSet: ${firewall_ipset} updated (as of: ${timestamp})."
	fi
}


IP_RegEx() {

	# IPv4 Regular Expressions
	IPV4SEG='(25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])'			# doted decimal notation; no leading 0 (octal) or 0x (hexadecimal)
	IPV4ADDR='(('${IPV4SEG}'\.){3,3}('${IPV4SEG}'){1,1})'
	IPV4CIDR='(3[0-2]|[12]?[0-9])'

	# IPv6 Regular Expressions
	IPV6SEG='[0-9a-fA-F]{1,4}'								# colon hextet notation; leading 0 permitted

	IPV6SEG8='('${IPV6SEG}':){7,7}('${IPV6SEG}'){1,1}'		# 1:2:3:4:5:6:7:8
	IPV6SEG7='('${IPV6SEG}':){1,7}(:''){1,1}'				# 1::                                 1:2:3:4:5:6:7::
	IPV6SEG6='('${IPV6SEG}':){1,6}(:'${IPV6SEG}'){1,1}'		# 1::8               1:2:3:4:5:6::8   1:2:3:4:5:6::8
	IPV6SEG5='('${IPV6SEG}':){1,5}(:'${IPV6SEG}'){1,2}'		# 1::7:8             1:2:3:4:5::7:8   1:2:3:4:5::8
	IPV6SEG4='('${IPV6SEG}':){1,4}(:'${IPV6SEG}'){1,3}'		# 1::6:7:8           1:2:3:4::6:7:8   1:2:3:4::8
	IPV6SEG3='('${IPV6SEG}':){1,3}(:'${IPV6SEG}'){1,4}'		# 1::5:6:7:8         1:2:3::5:6:7:8   1:2:3::8
	IPV6SEG2='('${IPV6SEG}':){1,2}(:'${IPV6SEG}'){1,5}'		# 1::4:5:6:7:8       1:2::4:5:6:7:8   1:2::8
	IPV6SEG1='('${IPV6SEG}':){1,1}(:'${IPV6SEG}'){1,6}'		# 1::3:4:5:6:7:8     1::3:4:5:6:7:8   1::8

	IPV6SEG0=':((:'${IPV6SEG}'){1,7}|:)'					#  ::2:3:4:5:6:7:8    ::2:3:4:5:6:7:8  ::8       ::

	IPV6LLZI='[fF][eE]80:(:'${IPV6SEG}'){0,4}%[0-9a-zA-Z]{1,}'	# fe80::7:8%eth0     fe80::7:8%1  (link-local IPv6 addresses with zone index)
	IPV6V4TRN='::([fF]{4,4}(:0{1,4}){0,1}:){0,1}'${IPV4ADDR}	# ::255.255.255.255  ::ffff:255.255.255.255  ::ffff:0:255.255.255.255 (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
	IPV6V4EMB='('${IPV6SEG}':){1,4}:'${IPV4ADDR}				# 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33 (IPv4-Embedded IPv6 Address)

	IPV6ADDR='('\
'('${IPV6SEG8}')|('${IPV6SEG7}')|('${IPV6SEG6}')|('${IPV6SEG5}')|('${IPV6SEG4}')|('${IPV6SEG3}')|('${IPV6SEG2}')|('${IPV6SEG1}')|('${IPV6SEG0}')|'\
'('${IPV6LLZI}')|('${IPV6V4TRN}')|('${IPV6V4EMB}')'\
')'

	IPV6CIDR='(12[0-8]|(1[01]|[1-9])?[0-9])'


	# Assign IPv4 or IPv6 RegEx
	if [ "$ip_version" == "IPv6" ]; then
		IPADDR=${IPV6ADDR}
		IPCIDR=${IPV6CIDR}
	else
		IPADDR=${IPV4ADDR}
		IPCIDR=${IPV4CIDR}
	fi

	# Double backslashes (escape) needed for RegEx strings for use in awk.  Replace each backslash in RegEx with two backslashes.
	IPADDR_2Esc=${IPADDR//\\/\\\\}
}


ipv_split_data_file() {

	split_rc=1

	# IPv split target into ipv data file
	if [ "$ip_version" == "IPv6" ]; then
		grep -Ev "$IPV4ADDR(/$IPV4CIDR)?" ${data_file}.tmp >${data_file}.ipv
	else
		grep -Ev "$IPV6ADDR(/$IPV6CIDR)?" ${data_file}.tmp >${data_file}.ipv
	fi

	if [ $? -eq 0 ]; then
		cmp -s -n 4194304 ${data_file}.ipv ${data_file}
		if [ $? -eq 1 ]; then
			mv -f ${data_file}.ipv ${data_file}
			split_rc=$?
		else
			rm -f ${data_file}.ipv
		fi
	fi
}


main() {
	command=$1
	ip_version=$2

	if [ "$command" == "restore" ]; then
		restore_ipset
	fi

	if [ "$command" == "load" ]; then
		IP_RegEx
		create_apply_ipset
	fi

	if [ "$command" == "save" ]; then
		save_ipset
	fi

	if [ "$command" == "unload" ]; then
		ipset flush ${firewall_ipset}
	fi

	if [ "$command" == "delete" ]; then
		rm -f ${data_file}
		rm -f ${data_dir}/${firewall_ipset}.set
		ipset flush ${firewall_ipset}
		ipset destroy ${firewall_ipset}
	fi

	if [ "$command" == "update" ] || [ "$command" == "" ]; then
			IP_RegEx
			get_target
	fi
}
