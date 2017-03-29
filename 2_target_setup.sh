#!/bin/bash                                                                                                                                                                         

REBOOT=$1
REDHAT_MAJOR_VERSION=`cat /etc/redhat-release | cut -d" " -f 4 | cut -d. -f 1`
yum remove OpenJDK
yum -y install telnet wireshark tcpdump screen lynx links lsof mysql rng-tools
yum -y install install cloudera-manager-agent
yum -y install krb5-workstation krb5-libs
service ntpdate stop
service ntpd stop


if [ $REDHAT_MAJOR_VERSION -eq 6 ]; then

  cp /etc/sysconfig/clock /etc/sysconfig/_clock.orig.`date +%d%m%y`
  cat > /etc/sysconfig/clock <<EOF
EOF
  ZONE="America/New_York"
  UTC=True
  EOF
  
  ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
  
 chkconfig postfix off
 service postfix stop
 chkconfig cups off
 service cups stop
 service iptables stop
 service ip6tables stop
 chkconfig iptables off
 chkconfig ip6tables off
 chkconfig nscd start
 chkconfig ncsd on
 
fi

if [ $REDHAT_MAJOR_VERSION -eq 7 ]; then

 timedatectl set-timezone UTC
 systemctl stop firewalld
 systemctl disable firewalld
 
 systemctl stop cups
 systemctl disable cups

 systemctl stop dhcpd
 systemctl disable dhcpd
  systemctl stop avahi-daemon
 systemctl disable avahi-daemon
 # not using nfs
 systemctl stop rpcidmapd
 systemctl disable rpcidmapd
 systemctl stop netfs
 systemctl disable netfs
 systemctl start nscd
 systemctl enable nscd
 systemctl status nscd
fi

ntpdate 0.rhel.pool.ntp.org

service ntpdate start
service ntpd start



echo "options ipv6 disable=1" >> /etc/modprobe.d/disabled.conf
echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network

echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6

echo -e 'Host *\nUseRoaming no' >> /etc/ssh/ssh_config

sed -i -e 's/#AddressFamily any/AddressFamily inet/'  /etc/ssh/sshd_config

sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 
sed -i -e 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config



cp /etc/rc.local /etc/sysconfig/_rc.local.orig.`date +%d%m%y%H%M%S`



# Set swappiness to minimum
echo "vm.swappiness = 1" >> /etc/sysctl.conf

#other sysctl settings from csco @ PNC 
# Disable response to broadcasts.
net.ipv4.icmp_echo_ignore_broadcasts = 1
# enable route verification on all interfaces
net.ipv4.conf.all.rp_filter = 1
# enable ipV6 forwarding
#net.ipv6.conf.all.forwarding = 1
# increase the number of possible inotify(7) watches
fs.inotify.max_user_watches = 65536
# avoid deleting secondary IPs on deleting the primary IP
net.ipv4.conf.default.promote_secondaries = 1
net.ipv4.conf.all.promote_secondaries = 1
# Hadoop
# arp_filter - With arp_filter set to 1, the kernel only answers to an ARP request if it matches its own IP address.
net.ipv4.conf.all.arp_filter = 1

# the percentage of system memory that can be filled with “dirty” pages — memory pages that still need to be written to disk
# before the pdflush/flush/kdmflush background processes kick in to write it to disk. below setting is 1%
vm.dirty_background_ratio = 1

#Heuristic overcommit handling. Obvious overcommits of address space are refused. Used for a typical system. It
# ensures a seriously wild allocation fails while allowing overcommit to reduce swap usage.  root is allowed to 
# allocate slightly more memory in this mode. This is the default.
#vm.overcommit_memory = 0

# This sets the max OS receive buffer size for all types of connections.
net.core.rmem_max = 16777216

# This sets the max OS send buffer size for all types of connections.
net.core.wmem_max = 16777216

# TCP Autotuning setting. "The first value tells the kernel the minimum receive buffer for each TCP connection, 
# and this buffer is always allocated to a TCP socket, even under high pressure on the system. ... The second value 
# specified tells the kernel the default receive buffer allocated for each TCP socket. This value overrides the 
# /proc/sys/net/core/rmem_default value used by other protocols. ... The third and last value specified in this 
# variable specifies the maximum receive buffer that can be allocated for a TCP socket." 
net.ipv4.tcp_rmem = 4096 87380 16777216

# TCP Autotuning setting. "This variable takes 3 different values which holds information on how much TCP sendbuffer memory 
# space each TCP socket has to use. Every TCP socket has this much buffer space to use before the buffer is filled up. Each of 
# the three values are used under different conditions. ... The first value in this variable tells the minimum TCP send buffer 
# space available for a single TCP socket. ... The second value in the variable tells us the default buffer space allowed for 
# a single TCP socket to use. ... The third value tells the kernel the maximum TCP send buffer space." a 
net.ipv4.tcp_wmem = 4096 65536 16777216


# man 7 tcp
# This parameter controls TCP Packetization-Layer Path MTU Discovery. The following values may be assigned to the file:
# 0 Disabled
# 1 Disabled by default, enabled when an ICMP black hole detected
# 2 Always enabled, use initial MSS of tcp_base_mss.
net.ipv4.tcp_mtu_probing=1
 

RCLOCALDONE=`grep -c THP /etc/rc.local`

if [ $RCLOCALDONE -ne 1 ]; then

cat <<EOF >> /etc/rc.local

##### CDH Settings ########################################
#disable  THP
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# set RPS settings
# needs advanced network services. run this command to test and look for ixgbevf 
# see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/enhanced-networking.html#enhanced-networking-linux for ec2
# ethtool -i eth0
# driver: ixgbevf

#gce
echo "7f" > /sys/devices/pci0000:00/0000:00:04.0/virtio1/net/eth0/queues/rx-0/rps_cpus
#echo "7f" > /sys/devices/vif-0/net/eth0/queues/rx-0/rps_cpus

# Enable TCP no delay: 
# the TCP stack makes decisions that prefer lower latency as opposed to higher throughput.
echo "1" > /proc/sys/net/ipv4/tcp_low_latency

#############################################

 
EOF

fi

EXITZERO=`grep -c 'exit 0' /etc/rc.local`
if [ $EXITZERO -eq 1 ]; then
  sed -i -e 's/exit 0/#exit 0/' /etc/rc.local
  echo "exit 0" >> /etc/rc.local
fi

chmod +x /etc/rc.d/rc.local

if [ "$REBOOT" == "reboot" ]; then
reboot
fi


