#! /bin/bash

# Check for prerequisite packages.
rpm -q ipset &>/dev/null ; [[ $? -ne 0 ]] && ret=1 && echo "ipset package is a prerequisite; yum -y install ipset"
rpm -q ipset-service &>/dev/null ; [[ $? -ne 0 ]] && ret=1 && echo "ipset-service package is a prerequisite; yum -y install ipset-service"
#rpm -q iptables &>/dev/null ; [[ $? -ne 0 ]] && ret=1 && echo "iptalbes package is a prerequisite; yum -y install iptables"
#rpm -q iptables-services &>/dev/null ; [[ $? -ne 0 ]] && ret=1 && echo "iptables-services package is a prerequisite; yum -y install iptables-services"
#rpm -q crontabs &>/dev/null ; [[ $? -ne 0 ]] && ret=1 && echo "crontabs package is a prerequisite; yum -y install crontabs"
#rpm -q rsyslog &>/dev/null ; [[ $? -ne 0 ]] && ret=1 && echo "rsyslog package is a prerequisite; yum -y install rsyslog"

if [[ $ret -ne 0 ]]; then
	echo ""
	echo "The prerequisites need to be installed first."
fi


# Install the ADF

DIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
#. "$DIR/Block_Lists_Main.sh"

echo $DIR/../src

ls -la $DIR/../src

/usr/libexec/ipset/ipset.start-stop save	# Save the currently loaded IP sets individually.

# Install ADF

# Put the ADF files in place.
cp -r --preserve=all $DIR/../src/usr/local/libexec/* /usr/local/libexec


# Add ADF cron jobs and logging.
#cp --preserve=all $DIR/../src/etc/cron.d/* /etc/cron.d
#cp --preserve=all $DIR/../src/etc/logrotate.d/* /etc/logrotate.d
#cp --preserve=all $DIR/../src/etc/rsyslog.d/* /etc/rsyslog.d

# Restart rsyslog
#systemctl restart rsyslog
