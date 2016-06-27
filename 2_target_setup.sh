#!/bin/bash                                                                                                                                                                         

REBOOT=$1
REDHAT_MAJOR_VERSION=`cat /etc/redhat-release | cut -d" " -f 4 | cut -d. -f 1`

yum -y install telnet wireshark tcpdump screen lynx links lsof mysql

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

RCLOCALDONE=`grep -c THP /etc/rc.local`

if [ $RCLOCALDONE -ne 1 ]; then

cat <<EOF >> /etc/rc.local

##### CDH Settings ########################################
#disable  THP
echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

# set RPS settings
# needs advanced network services. run this command to test and look for ixgbevf 
# see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/enhanced-networking.html#enhanced-networking-linux for ec2
# ethtool -i eth0
# driver: ixgbevf
echo "7f" > /sys/devices/vif-0/net/eth0/queues/rx-0/rps_cpus

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


