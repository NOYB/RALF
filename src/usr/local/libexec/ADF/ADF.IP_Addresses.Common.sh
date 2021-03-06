#!/bin/bash

# Copyright (c) 2010-2017 Al Stu, All rights reserved.

# Automated Dynamic Firewall - Common Code
Version="0.0.1"
Date="Aug 8, 2010"

#
# Begin - System Config Common Constants
#

System_Config_Common() {
	Server_Name=$(hostname)
	PERM_BLOCK_FILE_EXT="Static"
}

#
# End - System Config Common Constants
#


# Regular Expression (RegEx) Patterns
RegEx_Patterns_Common() {

	 Year_RegEx='([1-9][0-9]{0,3})'
	Month_RegEx='(0?[1-9]|1[[0-2])'
	  Day_RegEx='(0?[1-9]|[12][0-9]|3[0-1])'
	Time_24_HHMMss_RegEx='([01]?[0-9]|2[0-4])(:[0-5]?[0-9]){1,2}'

	Month_Name_RegEx='(January|February|March|April|May|June|July|August|September|October|November|December)'
	Month_Abbr_RegEx='(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
	Month_Alpha_RegEx="$Month_Abbr_RegEx|$Month_Name_RegEx"

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

	Server_Name_RegEx=$Server_Name
}


Main() {
	System_Config_Common
	System_Config_App_Specific

	Process_Command_Line_Syntax_Check $@
}


# Display Syntax Info
Syntax_Info_Display() {

	echo ""
	echo "$0"
	echo ""
	echo "Version: $Version Date: $Date"
	echo ""
}


# Process Command Line & Check Syntax
Process_Command_Line_Syntax_Check() {

	case "$1" in
	'')
#		if [ "${#@}" -eq "0" ]; then
			Update_Check
#		else Syntax_Info_Display
#		fi
		;;
	*)
		Syntax_Info_Display
	esac
}


Update_Check() {
	# Check log file time to see if need to continue.
	# No need to run if log file has not been updated since last run.
	# To force a run uncomment the following touch command, or run from command line (replace variables with literal dir/filename string).
	#touch -m "${LOG_FILES_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}"	# (for dev & debug)

	for LOG_SET in "${LOG_SETS[@]}"
	do
		LOG_SET=($LOG_SET)				# Convert string to array (space delimited)
		LOG_FILE_NAME=${LOG_SET[0]}
		if [ ${#LOG_SET[@]} -eq 6 ]; then
			INSTANCE_DIR=${LOG_SET[5]}"/"
		else
			INSTANCE_DIR=""
		fi

		if [ -f "${LOG_FILES_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}" ] && [ -f "${ADF_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}.ADF.IP_Addresses.Log" ]; then
			if  [ $(date -r "${LOG_FILES_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}" +%Y%m%d%H%M%S) -ge $(date -r "${ADF_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}.ADF.IP_Addresses.Log" +%Y%m%d%H%M%S) ] || \
			    [ $(date -r "${ADF_DIR}${INSTANCE_DIR}ADF.IP_Addresses.$SERVICE_NAME.$PERM_BLOCK_FILE_EXT" +%Y%m%d%H%M%S) -ge $(date -r "${ADF_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}.ADF.IP_Addresses.Log" +%Y%m%d%H%M%S) ]; then
				RUN
				break
			fi
		else
			RUN
			break
		fi
	done

#	RUN		# Force it to run!	# (for dev & debug)
}


RUN() {
	RegEx_Patterns_Common
	RegEx_Patterns_App_Specific

	# Process each log set.
	for LOG_SET in "${LOG_SETS[@]}"
	do
		LOG_SET=($LOG_SET)				# Convert string to array (space delimited)

		LOG_FILE_NAME=${LOG_SET[0]}
		NUM_LOG_FILE_VERSIONS=${LOG_SET[1]}
		TYPES_PREFIX=${LOG_SET[2]}
		LOG_SET_CATEGORY=${LOG_SET[3]}
		TYPES_NAME=${LOG_SET[4]}
		if [ ${#LOG_SET[@]} -eq 6 ]; then
			INSTANCE_DIR=${LOG_SET[5]}"/"
		else
			INSTANCE_DIR=""
		fi

		# Get the log set types array.
		TYPES_NAME_TMP=$TYPES_NAME[@]
		TYPES=("${!TYPES_NAME_TMP}")

		# Get the log set common RegEx for what content to use from the log file versions.
		Common_Scrape_RegEx_Name=$LOG_SET_CATEGORY"_Scrape_RegEx"
		Common_Scrape_RegEx=${!Common_Scrape_RegEx_Name}

		GET_LOG_SET_FILES				#    Get the log set file versions.
		SCRAPE_LOG_SET_FILES			# Scrape the log set file versions.
		SCRAPE_LOG_SET_TYPES			# Scrape the log set for the defined types.
	done

	Finish								# Clean up and call the IP set script.
}


GET_LOG_SET_FILES() {
	# Build LOG_FILES List (Array) (in oldest first order)
	unset LOG_FILES
	unset LOG_FILES_tmp

	local -i i=0
	for FILE in `ls -v "$LOG_FILES_DIR$INSTANCE_DIR$LOG_FILE_NAME"*`
	do
		if [ $i -lt $NUM_LOG_FILE_VERSIONS ]; then
			LOG_FILES_tmp[$i]=$FILE
			(( ++i ))
		else
			break
		fi
	done

	# Include the permanent list file (create first if doesn't exists)
	if [ ! -e "${ADF_DIR}${INSTANCE_DIR}ADF.IP_Addresses.${SERVICE_NAME}.${PERM_BLOCK_FILE_EXT}" ]; then
		mkdir -p "${ADF_DIR}${INSTANCE_DIR}"
		cat << EOT >> "${ADF_DIR}${INSTANCE_DIR}ADF.IP_Addresses.${SERVICE_NAME}.${PERM_BLOCK_FILE_EXT}"
Place (cut/paste) into this file, log file entries that are to be permanently included.
To use as a separate "static" type, append a key such as " STATIC" to an entry, and add a matching type to the "TYPES" array, ex "<category> STATIC 1 DROP", and a matching regular expression for the type.
EOT
	fi

	LOG_FILES_tmp[$i]=$ADF_DIR$INSTANCE_DIR"ADF.IP_Addresses."$SERVICE_NAME"."$PERM_BLOCK_FILE_EXT

	# Reverse the array of log files (put in oldest first order)
	for (( i=0, idx=${#LOG_FILES_tmp[@]}-1 ; idx>=0 ; i++, idx-- )) ; do
		LOG_FILES[$i]="${LOG_FILES_tmp[idx]}"
	done
	unset LOG_FILES_tmp
}

SCRAPE_LOG_SET_FILES() {
	# Scrape the log file versions for matching entries and output to file for repetitive use by each type.

	# Double backslashes (escape) needed for RegEx strings for use in awk.  Replace each backslash in RegEx with two backslashes.
	Common_Scrape_RegEx_2Esc=${Common_Scrape_RegEx//\\/\\\\}

	for LOG_FILE in "${LOG_FILES[@]}"
	do
		Scrape_Log_Set_Files+=$(cat "$LOG_FILE" \
		|awk --posix -F "[][ ]" -v Log_RegEx="$Common_Scrape_RegEx_2Esc" '{ if ($0 ~ Log_RegEx) print $0 }')
		Scrape_Log_Set_Files+=$'\n'		# Add a newline at end of each log file version.
	done

	File_Update "$Scrape_Log_Set_Files" "${ADF_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}.ADF.IP_Addresses.Log"
	unset Scrape_Log_Set_Files

#		|awk --posix -F "[][ ]" -v Log_RegEx="$NOQUEUE_Reject_RegEx" '{ if ($0 ~ Log_RegEx) print $0 }' \
#		|awk --posix -F "[][ ]" -v Log_RegEx="$NOQUEUE_Reject_RegEx" -v Current_Year=$(date +%Y) -v Current_Month=$(date +%m) -v Months_Abbrs="Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec" ' { if ($0 ~ Log_RegEx) { if ( (index(Months_Abbrs,$1)+3)/4 > Current_Month) Log_Year--; else Log_Year = Current_Year; print Log_Year " " $0 } }'
}


SCRAPE_LOG_SET_TYPES() {
	# Process each type
#	for TYPE in ${TYPES[*]}
#	for TYPE in ${TYPES[@]}
#	for TYPE in "${TYPES[*]}"
	for TYPE in "${TYPES[@]}"
	do
		TYPE=($TYPE)				# Convert string to array (space delimited)
		CATEGORY=${TYPE[0]}
		TYPENAME=${TYPE[1]}
		COUNT=${TYPE[2]}
		FIREWALL_ACTION=${TYPE[3]}

		CHAIN=$TYPES_PREFIX"_"$CATEGORY"_"$TYPENAME
		Log_RegEx_Name=$CATEGORY"_"$TYPENAME"_RegEx"
		Log_RegEx=${!Log_RegEx_Name}

		# Double backslashes (escape) needed for RegEx strings for use in awk.  Replace each backslash in RegEx with two backslashes.
		Log_RegEx_2Esc=${Log_RegEx//\\/\\\\}
		IPV4ADDR_2Esc=${IPV4ADDR//\\/\\\\}
		IPV6ADDR_2Esc=${IPV6ADDR//\\/\\\\}

		# Status & Working Files
		FILE_NAME_TYPE_LOG=$ADF_DIR$INSTANCE_DIR$LOG_FILE_NAME"."$CATEGORY"_"$TYPENAME".IP_Addresses.Log"

		Log_Set_Type_Scrape

		if [ $VERBOSE ]; then
			printf "\n%s\n%s\n" "$CATEGORY $TYPENAME IP Addresses Log", "$(cat "$FILE_NAME_TYPE_LOG")"
		fi

		Log_Set_Type_Finish

	done

	Log_Set_Finish
}


Log_Set_Type_Scrape() {
	# Scrape Log Files for Entries to Include
	# printf "\n%s\n" "$CATEGORY $TYPENAME IP Addresses Log"
	# 1) awk - Scrape log file for entries of interest using awk with Log_RegEx regular expression and output (print) desired fields (month, day, time, IP address).
	# 2) sort - Sort in reverse order by IP address, date, and time fields (newest first).
	# 3) uniq - Remove duplicate IP address lines (-f 0 skip no fields; start with first field/column; -w 18 compare only IP address field/column width) and prefix lines with count of occurrences (duplicates plus original).
	# 4) sort - Chronologically (oldest first) (iptables insert will result in newest first/top firewall chain rule order).
	# 5) Save results to file for later use.
	local LOG_SET_TYPE_SCRAPE=''
	LOG_SET_TYPE_SCRAPE=$(cat "${ADF_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}.ADF.IP_Addresses.Log" \
	|awk --posix -F "[][]| +" \
	-v Log_RegEx="$Log_RegEx_2Esc" \
	-v IPv4_RegEx="$IPV4ADDR_2Esc(/$IPV4CIDR)?" \
	-v IPv6_RegEx="$IPV6ADDR_2Esc(/$IPV6CIDR)?" \
	'{ \
		if ($0 ~ Log_RegEx) { \
			match($0,IPv4_RegEx); \
			IPv4_Addr=substr($0,RSTART,RLENGTH); \
			if (IPv4_Addr) {printf "%-18s %s\n", IPv4_Addr, $0} \
			match($0,IPv6_RegEx); \
			IPv6_Addr=substr($0,RSTART,RLENGTH); \
			if (IPv6_Addr) {printf "%-18s %s\n", IPv6_Addr, $0} \
		} \
	}' \
	)

	local Log_Set_Type_IP_Addresses=''
	Log_Set_Type_IP_Addresses=$(Log_Set_Type_Scrape_Unique "$LOG_SET_TYPE_SCRAPE")		# Call the app specific sort and unique function.

	File_Update "$Log_Set_Type_IP_Addresses" "$FILE_NAME_TYPE_LOG"

	IPv4_Addr_FIELD='2'	# Log_Set_Type_Finish() needs the IP address field (column) number.
	IPv6_Addr_FIELD='2'	# Log_Set_Type_Finish() needs the IP address field (column) number.
}


Log_Set_Type_Finish() {
	# Create ADF DROP list containing only IP addresses from scraped log files.
	# 1) awk - Scrape specified type log file for entries using awk with IPv4 & IPv6 regular expressions and output (print) desired fields (source IP address).

	local Log_Set_Type_Header=''
	Log_Set_Type_Header+="# $CHAIN (source addresses with $COUNT or more reject hits)"
	Log_Set_Type_Header+=$'\n'					# Add a newline to log set type header.

	local Log_Set_Type_IP_Addresses=''
	Log_Set_Type_IP_Addresses=$(cat "$FILE_NAME_TYPE_LOG" \
	|awk --posix \
	-v IPv4_RegEx="$IPV4ADDR_2Esc(/$IPV4CIDR)?" \
	-v IPv6_RegEx="$IPV6ADDR_2Esc(/$IPV6CIDR)?" \
	-v COUNT=$COUNT \
	-v IPv4_Addr_FIELD=$IPv4_Addr_FIELD \
	-v IPv6_Addr_FIELD=$IPv6_Addr_FIELD \
	'{ \
		if (($1 >= COUNT) && ($IPv4_Addr_FIELD ~ IPv4_RegEx)) {print ($IPv4_Addr_FIELD) } \
		if (($1 >= COUNT) && ($IPv6_Addr_FIELD ~ IPv6_RegEx)) {print ($IPv6_Addr_FIELD) } \
	 }' \
	|sort -V |uniq)

	if [ "$Log_Set_Type_IP_Addresses" ]; then
		Log_Set_Type_IP_Addresses+=$'\n'		# Add a newline at end of each log set type.
	fi

	Log_Set_Type_IP_Addresses_new+="$Log_Set_Type_Header"
	Log_Set_Type_IP_Addresses_new+="$Log_Set_Type_IP_Addresses"
}


Log_Set_Finish() {
	# Only need to update the *.ADF.IP_Addresses.DROP file when there are changes.

	File_Update "$Log_Set_Type_IP_Addresses_new" "${ADF_DIR}${INSTANCE_DIR}${LOG_FILE_NAME}.ADF.IP_Addresses.DROP"

	Log_Set_IP_Addresses_new+="$Log_Set_Type_IP_Addresses_new"

	unset Log_Set_Type_IP_Addresses_new
}


Finish() {
	# Only need to update the *.ADF.IP_Addresses.$Service.DROP file when there are changes.

	File_Update "$Log_Set_IP_Addresses_new" "${ADF_DIR}ADF.IP_Addresses.${SERVICE_NAME}.DROP"

	unset Log_Set_IP_Addresses_new

	"${IPSET_SCRIPT_IPv4[@]}"
	"${IPSET_SCRIPT_IPv6[@]}"
}


File_Update() {
	local str_content="$1"
	local file_name="$2"
	local file_content=''

	str_content=$(trim "$str_content" $'\n')		# Strip leading & trailing new line.

	# Get contents of the *.ADF.IP_Addresses.* file and update if there are changes.  Create if not exist.
	if [ -r "$file_name" ]; then
		file_content="$(<"$file_name")"
		file_content=$(trim "$file_content" $'\n')	# Strip leading & trailing new line.

		if [ "$str_content" != "$file_content" ]; then
			printf "%s" "$str_content" >"$file_name"
		fi
	else
		printf "%s" "$str_content" >"$file_name"
	fi
}


# Strip leading white space (new line inclusive).
ltrim(){
	local trim_chrs="[:space:]"

	if [ "$2" ]; then
		trim_chrs="$2"
	fi

	[[ "$1" =~ ^["$trim_chrs"]*(.*[^"$trim_chrs"]) ]]
	printf "%s" "${BASH_REMATCH[1]}"
}

# Strip trailing white space (new line inclusive).
rtrim(){
	local trim_chrs="[:space:]"

	if [ "$2" ]; then
		trim_chrs="$2"
	fi

	[[ "$1" =~ ^(.*[^"$trim_chrs"])["$trim_chrs"]*$ ]]
	printf "%s" "${BASH_REMATCH[1]}"
}

# Strip leading and trailing white space (new line inclusive).
trim(){
	local trim_chrs="[:space:]"

	if [ "$2" ]; then
		trim_chrs="$2"
	fi

	[[ "$1" =~ ^["$trim_chrs"]*(.*[^"$trim_chrs"])["$trim_chrs"]*$ ]]
	printf "%s" "${BASH_REMATCH[1]}"
}
