#!/bin/bash                                                                                                                                                                         
HOSTFILE=/tmp/etc.hosts

cat /tmp/etc.hosts >> /etc/hosts


sudo rpm -U /tmp/jdk-7u51-linux-x64.rpm
sudo yum -y install mysql-connector-java

yum -y install telnet wireshark tcpdump screen lynx links lsof mysql

service ntpdate stop
service ntpd stop

cp /etc/sysconfig/clock /etc/sysconfig/_clock.orig.`date +%d%m%y`
cat > /etc/sysconfig/clock <<EOF
ZONE="America/New_York"
UTC=True
EOF

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime


ntpdate 0.rhel.pool.ntp.org

service ntpdate start
service ntpd start
chkconfig postfix off
service postfix stop
chkconfig cups off
service cups stop
service iptables stop
service ip6tables stop
chkconfig iptables off
chkconfig ip6tables off

sed -i -e s/SELINUX=enforcing/SELINUX=disabled/ /etc/selinux/config 
sed -i -e s/SELINUX=permissive/SELINUX=disabled/ /etc/selinux/config

cp /etc/rc.local /etc/sysconfig/_rc.local.orig.`date +%d%m%y%H%M%S`

# address the bug in some ec2 instances where they leave out the trailing EOL
EC2BUG=`grep -c EOL /etc/rc.local`

# Set swappiness to minimum
echo "vm.swappiness = 0 >> /etc/sysctl.conf"


if [ $EC2BUG -eq 1 ]; then
    echo -e "\n\nEOL" >> /etc/rc.local
fi
cat <<EOF >> /etc/rc.local

##### CDH Settings ########################################
#disable  THP
echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled

# set RPS settings
echo "7f" > /sys/devices/vif-0/net/eth0/queues/rx-0/rps_cpus

# Enable TCP no delay:
echo "1" > /proc/sys/net/ipv4/tcp_low_latency

#############################################
 
EOF


reboot



