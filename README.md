# RALF
Reflex Active Linux Firewall<br>

#### What it is
 A dynamic firewall automation tool.<br>

#### What it Does
 Automates the populating of IP sets from log file contents for an automated dynamic firewall (ADF).<br>

#### Operation
 Monitors specified log files for status messages typically attributed to nefarious activity to glean the IP addresses and add them to an IP set used for filtering by the firewall (e.g. iptables).<br>
<br>
Once a log file version is rotated beyond the number of log file versions specified to be parsed, the IP addresses previously gleaned from that log file version are removed from the IP set when the script is next run.<br>

#### Benefits
 Utilizing dynamically generated IP sets with the firewall capabilities to automate the blocking of detected nefarious activity at the network firewall rather than at the application can:<br>
  1) Reduce system and network resource usage for processing nefarious activity.<br>
  2) Reduce log file size and clutter (log spam) so the logs are more manageable and efficient for gathering legitimate information.<br>
  3) Aid in fending off certain nefarious activities and attacks.<br>

#### Additionall details
See /src/usr/local/libexec/ADF/Manual/

#### Development System
 CentOS 7.6.1810<br>
 Kernel: Linux 3.10.0-957.5.1.el7.centos.plus.x86_64<br>
 GNU bash, version 4.2.46(2)-release (x86_64-redhat-linux-gnu)<br>
 IP Set v6.38<br>
 IP Tables v1.4.21<br>
 Postfix 2.10.1<br>
 BIND 9.9.4<br>

#### BASH Commands Used
 Built-in: declare/typeset/local, echo, exit, printf<br>
 External: awk, case, cat, clear, date, cmp, grep, mkdir, rm, sort, uniq<br>
