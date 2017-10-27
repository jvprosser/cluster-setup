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
