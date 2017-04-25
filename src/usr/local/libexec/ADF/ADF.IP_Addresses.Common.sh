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

	IPv4_RegEx='(([01]?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}([01]?[0-9]{1,2}|2[0-4][0-9]|25[0-5])'
	CIDR_RegEx='(/([12]?[0-9]|[3]?[0-2]))'

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
	#touch -m "$LOG_FILES_DIR$LOG_FILE_NAME"	# (for dev & debug)

	for LOG_SET in "${LOG_SETS[@]}"
	do
		LOG_SET=($LOG_SET)				# Convert string to array (space delimited)
		LOG_FILE_NAME=${LOG_SET[0]}

		if [ -f "$LOG_FILES_DIR$LOG_FILE_NAME" ] && [ -f "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.Log" ]; then
			if  [ $(date -r "$LOG_FILES_DIR$LOG_FILE_NAME" +%Y%m%d%H%M%S) -ge $(date -r "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.Log" +%Y%m%d%H%M%S) ] || \
			    [ $(date -r "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.$PERM_BLOCK_FILE_EXT" +%Y%m%d%H%M%S) -ge $(date -r "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.Log" +%Y%m%d%H%M%S) ]; then
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
	for FILE in "$LOG_FILES_DIR$LOG_FILE_NAME"*
	do
		if [ $i -lt $NUM_LOG_FILE_VERSIONS ]; then
			LOG_FILES_tmp[$i]=$FILE
			(( ++i ))
		else
			break
		fi
	done

	# Include the permanent list file (create first if doesn't exists)
	if [ ! -e "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.$PERM_BLOCK_FILE_EXT" ]; then
		mkdir -p "$ADF_DIR"
		cat << EOT >> "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.$PERM_BLOCK_FILE_EXT"
Place (cut/paste) into this file, log file entries that are to be permanently included.
To use as a separate "static" type, append a key such as " STATIC" to an entry, and add a matching type to the "TYPES" array, ex "<category> STATIC 1 DROP", and a matching regular expression for the type.
EOT
	fi

	LOG_FILES_tmp[$i]=$ADF_DIR"ADF.IP_Addresses."$SERVICE_NAME"."$PERM_BLOCK_FILE_EXT

	# Reverse the array of log files (put in oldest first order)
	for (( i=0, idx=${#LOG_FILES_tmp[@]}-1 ; idx>=0 ; i++, idx-- )) ; do
		LOG_FILES[$i]="${LOG_FILES_tmp[idx]}"
	done
	unset LOG_FILES_tmp
}

SCRAPE_LOG_SET_FILES() {
	# Scrape the log file versions for matching entries and output to file for repetitive use by each type.

	# Clear out previous contents - Start fresh with empty file
	printf "" >"$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.Log"
	printf "" >"$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP.tmp"

	# Double backslashes (escape) needed for RegEx strings for use in awk.  Replace each backslash in RegEx with two backslashes.
	Common_Scrape_RegEx_2Esc=${Common_Scrape_RegEx//\\/\\\\}

	for LOG_FILE in "${LOG_FILES[@]}"
	do
		cat "$LOG_FILE" \
		|awk --posix -F "[][ ]" -v Log_RegEx="$Common_Scrape_RegEx_2Esc" '{ if ($0 ~ Log_RegEx) print $0 }' \
		>>"$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.Log"
	done

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
		IPv4_RegEx_2Esc=${IPv4_RegEx//\\/\\\\}

		# Status & Working Files
		FILE_NAME_TYPE_LOG=$ADF_DIR$LOG_FILE_NAME"."$CATEGORY"_"$TYPENAME".IP_Addresses.Log"

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
	LOG_SET_TYPE_SCRAPE=$(cat "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.Log" \
	|awk --posix -F "[][]| +" -v Log_RegEx="$Log_RegEx_2Esc" -v IPv4_RegEx="$IPv4_RegEx_2Esc$CIDR_RegEx?" \
	'{ if ($0 ~ Log_RegEx) { \
	match($0,IPv4_RegEx); IPv4_Addr=substr($0,RSTART,RLENGTH); \
	printf "%-18s %s\n", IPv4_Addr, $0 } }')

	Log_Set_Type_Scrape_Unique "$LOG_SET_TYPE_SCRAPE"		# Call the app specific sort and unique function.

	IPv4_Addr_FIELD='2'	# Log_Set_Type_Finish() needs the IP address field (column) number.
}


Log_Set_Type_Finish() {
	# Just need to update the *.ADF.IP_Addresses.DROP file when there are changes.
	# Create ADF DROP list file containing only IP addresses from scraped log files.
	# 1) awk - Scrape specified type log file for entries using awk with IPv4_RegEx regular expression and output (print) desired fields (source IP address).
	printf "%s\n" "# $CHAIN (source addresses with $COUNT or more reject hits)" >>"$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP.tmp"
	cat "$FILE_NAME_TYPE_LOG" \
	|awk --posix -v IPv4_RegEx="$IPv4_RegEx_2Esc$CIDR_RegEx?" -v COUNT=$COUNT -v IPv4_Addr_FIELD=$IPv4_Addr_FIELD '{ if (($1 >= COUNT) && ($IPv4_Addr_FIELD ~ IPv4_RegEx)) print ($IPv4_Addr_FIELD) }' \
	|sort -V |uniq >>"$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP.tmp"
}


Log_Set_Finish() {
	if !(cmp -s "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP.tmp" "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP"); then
		mv "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP.tmp" "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP"
	fi

	if [ -f "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP.tmp" ]; then
		rm "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP.tmp"
	fi

	cat "$ADF_DIR$LOG_FILE_NAME.ADF.IP_Addresses.DROP" >>"$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.DROP.tmp"
}


Finish() {
	if !(cmp -s "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.DROP.tmp" "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.DROP"); then
		mv "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.DROP.tmp" "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.DROP"
	fi

	if [ -f "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.DROP.tmp" ]; then
		rm "$ADF_DIR/ADF.IP_Addresses.$SERVICE_NAME.DROP.tmp"
	fi

	"${IPSET_SCRIPT[@]}"
}
