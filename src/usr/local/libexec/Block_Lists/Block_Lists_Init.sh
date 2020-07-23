#! /bin/bash

DIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
#. "$DIR/file"

case "$1" in
	start|restart|restore)
	echo "Restore block lists"
	. "$DIR/ADF_DNS_DROP.sh"	restore
	. "$DIR/ADF_DNS_DROP.sh"	restore	IPv6
	. "$DIR/ADF_HTTP_DROP.sh"	restore
	. "$DIR/ADF_HTTP_DROP.sh"	restore	IPv6
	. "$DIR/ADF_SMTP_DROP.sh"	restore
	. "$DIR/ADF_SMTP_DROP.sh"	restore	IPv6
	. "$DIR/Full_Bogons.sh"		restore
	. "$DIR/Full_Bogons.sh"		restore	IPv6
	. "$DIR/Spamhaus_DROP.sh"	restore
	. "$DIR/Spamhaus_DROP.sh"	restore	IPv6
	. "$DIR/Spamhaus_EDROP.sh"	restore
	RETVAL=$?
	;;
	stop|unload)
	echo "Remove block lists"
	. "$DIR/ADF_DNS_DROP.sh"	unload
	. "$DIR/ADF_DNS_DROP.sh"	unload	IPv6
	. "$DIR/ADF_HTTP_DROP.sh"	unload
	. "$DIR/ADF_HTTP_DROP.sh"	unload	IPv6
	. "$DIR/ADF_SMTP_DROP.sh"	unload
	. "$DIR/ADF_SMTP_DROP.sh"	unload	IPv6
	. "$DIR/Full_Bogons.sh"		unload
	. "$DIR/Full_Bogons.sh"		unload	IPv6
	. "$DIR/Spamhaus_DROP.sh"	unload
	. "$DIR/Spamhaus_DROP.sh"	unload	IPv6
	. "$DIR/Spamhaus_EDROP.sh"	unload
	RETVAL=$?
	;;
	load)
	echo "Create block lists"
	. "$DIR/ADF_DNS_DROP.sh"	load
	. "$DIR/ADF_DNS_DROP.sh"	load	IPv6
	. "$DIR/ADF_HTTP_DROP.sh"	load
	. "$DIR/ADF_HTTP_DROP.sh"	load	IPv6
	. "$DIR/ADF_SMTP_DROP.sh"	load
	. "$DIR/ADF_SMTP_DROP.sh"	load	IPv6
	. "$DIR/Full_Bogons.sh"		load
	. "$DIR/Full_Bogons.sh"		load	IPv6
	. "$DIR/Spamhaus_DROP.sh"	load
	. "$DIR/Spamhaus_DROP.sh"	load	IPv6
	. "$DIR/Spamhaus_EDROP.sh"	load
	RETVAL=$?
	;;
	update)
	echo "Update block lists"
	. "$DIR/ADF_DNS_DROP.sh"	update
	. "$DIR/ADF_DNS_DROP.sh"	update	IPv6
	. "$DIR/ADF_HTTP_DROP.sh"	update
	. "$DIR/ADF_HTTP_DROP.sh"	update	IPv6
	. "$DIR/ADF_SMTP_DROP.sh"	update
	. "$DIR/ADF_SMTP_DROP.sh"	update	IPv6
	. "$DIR/Full_Bogons.sh"		update
	. "$DIR/Full_Bogons.sh"		update	IPv6
	. "$DIR/Spamhaus_DROP.sh"	update
	. "$DIR/Spamhaus_DROP.sh"	update	IPv6
	. "$DIR/Spamhaus_EDROP.sh"	update
	RETVAL=$?
	;;
esac
exit $RETVAL
