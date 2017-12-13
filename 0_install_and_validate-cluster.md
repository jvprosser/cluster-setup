## Hardware validation

 - [ ] Get Certtoolkit http://github.mtv.cloudera.com/CertTeam/CertToolkit/
 - [ ] Get clustershell http://clustershell.readthedocs.io/en/latest/index.html
 or
 - [ ] Get pssh 
 - [ ] yum install epel-release (if needed)
 - [ ] yum -y install python-pip 
 - [ ] pip install beautifulsoup4 cm_api paramiko pyyaml requests_ntlm

 - [ ] Identify RDBMS and get drivers.
 - [ ] Set up passwordless root login from CM host to all hosts.

### 1.    Validate Disks

 - [ ] clush -a -b 'df –h'
 - [ ] clush -a -b "dmesg | egrep -i 'sense error|ata bus error'"
 - [ ] clush -a -b check_disks.sh

```
#!/bin/bash
N = $1
for i in {01..$N}
do
dd bs=1M count=1024 if=/dev/zero of=/data$i/test oflag=direct conv=fdatasync
done

for i in {01..$N}
do
rm -f /data$i/test
done
```

 - [ ] Confirm /etc/fstab has defaults,noatime

### 2. NTP
clush -a -b 'ntpq -p'


### 2.    Kernel settings

 - [ ] clush -a -b 'cat /etc/sysctl.conf' | less
 - [ ] Check and fix swappiness

```
clush -a -b "sed -i 's/vm.swappiness = 0/vm.swappiness = 1/g' /etc/sysctl.conf"
echo 1 > /proc/sys/vm/swappiness
```
 - [ ] Check and fix the amount of swap available
 ```
 free -h
 ```
#### check rc.local
- [ ]  check THP 

 > ```
 >  cat /sys/kernel/mm/transparent_hugepage/defrag always madvise [never]   It should indicate [never] which means it's disabled
 >
 >     vi /etc/rc.local You should see these lines: 
 > # Begin Hadoop Configuration parameters e
 > echo never > /sys/kernel/mm/transparent_hugepage/defrag
 >     # End Hadoop Configuration parameters
 > ```

 - [ ]  systemctl status firewalld.service
 - [ ]  check SELINUX


#### Optional network performance improvements that could be made
 - [ ]  Receive Packet Steering – can help to offload  packet processing. Helps to prevent the hardware queue of a single network interface card from becoming a bottleneck in network traffic.
 >  https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Performance_Tuning_Guide/network-rps.html
 > `echo “7f” > /sys/devices/????/net/eth0/queues/rx-0/rps_cpus`

 - [ ]   Enable TCP no delay:

```
# the TCP stack makes decisions that prefer lower latency as opposed to higher throughput.
echo "1" > /proc/sys/net/ipv4/tcp_low_latency
```

### 3.    Validate network

 - [ ]  cat /etc/resolv.conf
 - [ ]  cat /etc/nsswitch.conf | grep hosts:
 - [ ]  cat /etc/host.conf
 - [ ]  dig @resolverip   hostname
 - [ ]  host hostip
 - [ ]  dig -x hostip
 - [ ]  nslookup hostname
 - [ ]  ping -c 2 localhost
 - [ ]  lsmod | grep ipv6
 - [ ]  cat /etc/sysconfig/network
 - [ ]  ethtool eth0 | grep Speed
 - [ ]  ethtool –S eth0 | grep collision
 - [ ]  ethtool –S eth0 | grep drop
 
 Configure CPUs for Performance Scaling

CPU Scaling is configurable and defaults commonly to favor power saving over performance. For Hadoop clusters, it is important that we configure then for better performance over other options.

Please set scaling governors to performance, which means running the CPU at maximum frequency.  To do so run `cpufreq-set -r -g performance` OR edit /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor and set the content to 'performance'


# add these to /etc/sysctl.conf
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

 >     NOTE: Consider running a DNS caching server (or more than one) inside the cluster for performance reasons.
 >     check for multiple host groups. look for differences and resolve if needed.
 >     Check errors then correct then run host inspector again
### 4.    Validate Java

   UAT Cloudera Installation
   - [ ]  Install  JDBC driver on CM server
   - [ ]  Check jdbc driver exists on all nodes that have services that connects to Oracle
   - [ ] wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jdk-8u144-linux-x64.tar.gz"


    If nodes do not have it  we need to install by copying from one of the nodes

    then move the file from /tmp to /usr/share/java on that node
    mv /tmp/RDBMS-connector-java.jar /usr/share/java/RDBMS-connector-java.jar

### 5.    Validate Cloudera software install

#### Setup repository
 - [ ]  Check repo to make sure it points to the correct internal site:
 - [ ]  Download the Spark2 CSD, chmod 644, chown cloudera-scm: , mv to /opt/cloudera/csd
 
 
 ### http://ip:7180/cmf/express-wizard/wizard

```
    $ cat /etc/yum.repos.d/Cloudera_Manager.repo
    [Cloudera_Manager]
    baseurl = http://repo.example.com/example/packages/Cloudera/cdh5/parcels/5.10.0/rhel7
    enabled = 1
    gpgcheck = 0
    name = Cloudera Package Repo

    $ yum clean all
    $ yum repolist
```


### Install CM server and agent on CM Node
   - [ ]  yum install cloudera-manager-daemons cloudera-manager-server
   - [ ] Install CM agent on CM Node
`   yum install cloudera-manager-agent cloudera-manager-daemons`

   - [ ] Edit the scm agent configuration to point to CM server

 >  `sed -i '3s/.*/server_host= cmhost.example.com/' /etc/cloudera-scm-agent/config.ini`

###    6.    Prepare RDBMS

   - [ ] Check connectivity to RDBMS via telnet
   - [ ] Run SCM Backend db prepare statement
 
 If successful, you should see the following:
 >     ```
 >     [root@CMHOST ~]# /usr/share/cmf/schema/scm_prepare_database.sh -h oracle-scan.qa.example.com oracle bdpdb10q_svc.qa.example.com cman
 >     Enter SCM password:
 >     JAVA_HOME=/usr/java/jdk1.7.0_67-cloudera
 >     Verifying that we can write to /etc/cloudera-scm-server
 >     Creating SCM configuration file in /etc/cloudera-scm-server
 >     Executing:  /usr/java/jdk1.7.0_67-cloudera/bin/java -cp /usr/share/java/mysql-connector-java.jar:/usr/share/java/oracle-connector-java.jar:/usr/share/cmf/schema/../lib/* com.cloudera.enterprise.dbutil.DbCommandExecutor /etc/cloudera-scm-server/db.properties com.cloudera.cmf.db.
 >     [                          main] DbCommandExecutor              INFO  Successfully connected to database.
 >     All done, your SCM database is configured correctly!
 >     [root@CMHOST ~]#
 >     ```

 ##      Cluster Installation

 ### 1.    Prepare CM Server

 - [ ] Start CM Server

   ```
     service cloudera-scm-server start

    tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
    ```

 - [ ] Start CM Agents

  ```
    service cloudera-scm-agent start
    tail -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log
  ```

 - [ ] Login to CM Web UI  (Use Chrome)

```
    http://lbdp15abu.uat.example.com:7180

    initial login:  username = admin    pw = admin

    Accept the license
```
 - [ ]  Install CM Agent on all remaining hosts (Note: it may already be installed)

   `clush -a -b  yum install cloudera-manager-agent cloudera-manager-daemons`

 - [ ] Edit the scm agent configuration to point to CM server

    `clush -a -b sed -i '3s/.*/server_host= cmhostexample.com/' /etc/cloudera-scm-agent/config.ini`

    or

    `for h in `cat ~pl38360/hosts.txt`; do echo $h; ssh $h sed -i \'3s/.*/server_host= cmhostexample.com/\' /etc/cloudera-scm-agent/config.ini ; done`


 - [ ] Restart CM Agent
```
    service cloudera-scm-agent restart
    tail -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log
```

 - [ ] CM, go 'Back' to have all the nodes show up in the list of nodes to add

      Click 'Currently Managed Hosts' tab
      Ensure all expected nodes are included in the list.
      Select (place checkmark) on all nodes. Click 'Continue'
      On the next screen, click 'More Options'
 
 - [ ] Add internal CDH parcel repository if needed

 - [ ] Resolve host inspector issues

### 1.    Check entropy
You can check the available entropy on a Linux system by running the following command:

- [ ] cat /proc/sys/kernel/random/entropy_avail

The output displays the entropy currently available. Check the entropy several times to determine the state of the entropy pool on the system. If the entropy is consistently low (500 or less), you must increase it by installing rng-tools and starting the rngd service.

```
sudo yum install rng-tools
cp /usr/lib/systemd/system/rngd.service /etc/systemd/system/
sed -i -e 's/ExecStart=\/sbin\/rngd -f/ExecStart=\/sbin\/rngd -f -r\/dev\/urandom/' /etc/systemd/system/rngd.service
systemctl daemon-reload$ systemctl start rngd$ systemctl enable rngd
```

###    4.    Assign services to hosts

 - [ ] hdfs blocksize = 128
 - [ ] failed volumes: half # disks
 - [ ] Set ZooKeeper root for Kafka to /kafka
 - [ ] Also checked Enable Kafka Monitoring (Note: Requires Kafka-1.3.0 parcel or higher)
 - [ ] get hardware specs and fill out the Yarn Tuning guide.
 - [ ] modify memory overcommit validation threshold if needed
 - [ ] ZooKeeper dataDir and dataLogDir need to be on their own dedicated disks (each)
 - [ ] Check YARN's logging directories.  There should be one for every disk used for HDFS storage
 - [ ] Check that Impala has  scratch directories configured, otherwise all spills go to /tmp.  This is bad for performance, and risks filling up /tmp quickly.
 - [ ] Impala > Configurations > Service-Wide > Advanced > Impala Command Line Argument Advanced Configuration Snippet (Safety Valve)  set --idle_session_timeout =180

 - [ ] Check that yarn log aggregation is enabled.

##    Benchmark/Smoketest

###    1.    Teragen
    ```
    export HADOOP_USER_NAME=hdfs

    hadoop jar /opt/cloudera/parcels/CDH/jars/hadoop-examples.jar teragen -Dmapreduce.job.maps=160 10000000000 /user/hdfs/teragen1TB

    hdfs dfs -du -s -h /user/hdfs/teragen1TB

    hdfs dfs -rm -r -f -skipTrash /user/hdfs/teragen1TB
    ```

- [ ] look for frame errors
 
  ```
    [root@ log]# netstat -ina
    Kernel Interface table
    Iface      MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
    eth0      9000 16154899      1      0 0      12845469      0      0      0 BMRU
    lo       65536    23065      0      0 0         23065      0      0      0 LRU
    ```


  - [ ] get job screen shots for doc
  - [ ] get CM graphs screen shots for doc
  - [ ] Resource Pool Usage
  - [ ] Cluster CPU/IO/Network

  Should see less I/O more network

###    2.    Terasort
  ```
    hadoop jar /opt/cloudera/parcels/CDH/jars/hadoop-examples.jar terasort /user/pl75230/teragen1TB /user/pl75230/terasort1TB
  ```

  - [ ] get job screen shots for doc
  - [ ] Resource Pool Usage
  - [ ] Cluster CPU/IO/Network
  - [ ] get CM graphs screen shots for doc

    Should see less network more I/O

### 3.   TeraValidate
    ```
    hadoop jar /opt/cloudera/parcels/CDH/jars/hadoop-examples.jar teravalidate /user/pl75230/terasort1TB /user/pl75230/teravalidate1TB
    ```
  - [ ] get job screen shots for doc
  - [ ] Resource Pool Usage
  - [ ] Cluster CPU/IO/Network
  - [ ] get CM graphs screen shots for doc
