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

	# IPv4 Regular Expressions
	IPv4_RegEx='(([01]?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}([01]?[0-9]{1,2}|2[0-4][0-9]|25[0-5])'
	CIDR_RegEx='(/([12]?[0-9]|[3]?[0-2]))'

	# Double backslashes (escape) needed for RegEx strings for use in awk.  Replace each backslash in RegEx with two backslashes.
	IPv4_RegEx_2Esc=${IPv4_RegEx//\\/\\\\}

	# Load the list into the new/temp set.  Ignoring any duplicate entries.
	cat ${data_file} \
	| awk --posix \
	-v IPv4_RegEx="$IPv4_RegEx_2Esc$CIDR_RegEx?" \
	'{ if ($1 ~ IPv4_RegEx) print ($1) }' \
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

		cp -p ${target} ${data_file}

		if [ $? -eq 0 ]; then

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


main() {
	command=$1

	if [ "$command" == "restore" ]; then
		restore_ipset
	fi

	if [ "$command" == "load" ]; then
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
			get_target
	fi
}
