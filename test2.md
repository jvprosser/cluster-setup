## Hardware validation

### 1.	Validate Disks

df –h

[ ]  cat /etc/fstab

[ ] `dmesg | egrep -i 'sense error';dmesg | egrep -i 'ata bus error'`


```
[root@CMHOST ~]# dd bs=1M count=1024 if=/dev/zero of=/data03/cloudera/var/log/test oflag=direct conv=fdatasync
1024+0 records in
1024+0 records out
1073741824 bytes (1.1 GB) copied, 11.0517 s, 97.2 MB/s



for i in {01..N}
do
dd bs=1M count=1024 if=/dev/zero of=/data$i/test oflag=direct conv=fdatasync
done

for i in {01..N}
do
rm -f /data$i/test
done
```

All tests positive


### 2.	Kernel settings


[ ]  cat /etc/sysctl.conf


[ ]  	check and fix swappiness
```
pssh "sed -i 's/vm.swappiness = 0/vm.swappiness = 1/g' /etc/sysctl.conf"
```

[ ]  systemctl status firewalld.service



[ ]  cat /etc/sysconfig/selinux | grep SELINUX



[ ]  cat /etc/rc.local

[ ]  had to remove “redhat_” from THP in rc.local
clush --all "sed -i 's/vm.swappiness = 0/vm.swappiness = 1/g' /etc/sysctl.conf"

Optional network performance improvements that could be made 
[ ]  Receive Packet Steering – can help to offload  packet processing. Helps to prevent the hardware queue of a single network interface card from becoming a bottleneck in network traffic. 
o	https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Performance_Tuning_Guide/network-rps.html
```
echo “7f” > /sys/devices/pci0000:00/0000:00:02.0/0000:03:00.0/0000:04:00.0/0000:05:00.0/0000:06:00.0/0000:07:00.0/net/eth0/queues/rx-0/rps_cpus
```

[ ]   Enable TCP no delay: 
```
# the TCP stack makes decisions that prefer lower latency as opposed to higher throughput.
echo "1" > /proc/sys/net/ipv4/tcp_low_latency
```


### 3.	Validate network

[ ]  cat /etc/resolv.conf
•	Done

[ ]  cat /etc/nsswitch.conf | grep hosts:
•	Done

[ ]  cat /etc/host.conf
	Done

[ ]  dig @192.88.246.102 lbdp15abu.uat.example.com

[ ]  host 1.2.3.4
•	Done/OK

[ ]  dig -x hostip

[ ]  nslookup lbdp15abu.uat.example.com

[ ]  ping -c 2 localhost

[ ]  lsmod | grep ipv6

[ ]  cat /etc/sysconfig/network

[ ]  ethtool eth0 | grep Speed


[ ]  ethtool –S eth0 | grep collision

[ ]  ethtool –S eth0 | grep drop


### 4.	Validate Java


UAT Cloudera Installation

[ ]  Install  JDBC driver on CM server
Note: This should already be installed via build script.

[ ]  Check jdbc driver exists on all nodes that have services that connects to Oracle 

If node did not have it and therefore we need to install by copying from one of the nodes
```
$ scp /usr/share/java/oracle-connector-java.jar pl75230@lbdp15bbe.uat.example.com:/tmp/
```
then move the file from /tmp to /usr/share/java on that node
mv /tmp/oracle-connector-java.jar /usr/share/java/oracle-connector-java.jar 

### 5.	Validate Cloudera software install

#### Setup repository
[ ]  Check repo to make sure it points to the correct internal site:



$ cat /etc/yum.repos.d/Cloudera_Manager.repo
[Cloudera_Manager]
baseurl = http://repo.example.com/example/packages/Cloudera/cdh5/parcels/5.10.0/rhel7
enabled = 1
gpgcheck = 0
name = Cloudera Package Repo

$ yum clean all
$ yum repolist
•	Done/OK


### Install CM server and agent on CM Node

[ ]  yum install cloudera-manager-daemons cloudera-manager-server


	
* Install CM agent on CM Node
yum install cloudera-manager-agent cloudera-manager-daemons
•	Done/OK

* Edit the scm agent configuration to point to CM server

sed -i '3s/.*/server_host= cmhost.example.com/' /etc/cloudera-scm-agent/config.ini

1.6	Prepare RDBMS

* Check firewall to Oracle server

telnet oracle-scan.prod.example.com 1521
telnet oracle-scan.prod.example.com  1521
•	Done/OK


* Run SCM Backend db prepare statement

/usr/share/cmf/schema/scm_prepare_database.sh -h oracle-scan.qa.example.com oracle bdpdb10q_svc.qa.example.com cman xxxxxxxxx

Note: database name = dbname
Contact DBA to enter database password 

If successful, you should see the following:
```
[root@CMHOST ~]# /usr/share/cmf/schema/scm_prepare_database.sh -h oracle-scan.qa.example.com oracle bdpdb10q_svc.qa.example.com cman
Enter SCM password:
JAVA_HOME=/usr/java/jdk1.7.0_67-cloudera
Verifying that we can write to /etc/cloudera-scm-server
Creating SCM configuration file in /etc/cloudera-scm-server
Executing:  /usr/java/jdk1.7.0_67-cloudera/bin/java -cp /usr/share/java/mysql-connector-java.jar:/usr/share/java/oracle-connector-java.jar:/usr/share/cmf/schema/../lib/* com.cloudera.enterprise.dbutil.DbCommandExecutor /etc/cloudera-scm-server/db.properties com.cloudera.cmf.db.
[                          main] DbCommandExecutor              INFO  Successfully connected to database.
All done, your SCM database is configured correctly!
[root@CMHOST ~]#
```

2	Cluster Installation
2.1	Prepare CM Server

* Start CM Server

service cloudera-scm-server start

tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log 

* Start CM Agent

service cloudera-scm-agent start

tail -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log

* Login to CM Web UI  (Use Chrome)

http://lbdp15abu.uat.example.com:7180

initial login:  username = admin    pw = admin

Accept the license

* Install CM Agent on all remaining hosts (Note: it may already be installed)

Using ssh, login and sudo yum install cloudera-manager-agent cloudera-manager-daemons

* Edit the scm agent configuration to point to CM server

sed -i '3s/.*/server_host= cmhostexample.com/' /etc/cloudera-scm-agent/config.ini

PuTTY Instructions
[root@CMHOST ~]# for h in `cat ~pl38360/hosts.txt`; do echo $h; ssh $h sed -i \'3s/.*/server_host= cmhostexample.com/\' /etc/cloudera-scm-agent/config.ini ; done


* Restart CM Agent

service cloudera-scm-agent restart

tail -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log


In CM, go 'Back' to have all the nodes show up in the list of nodes to add

Click 'Currently Managed Hosts' tab

Ensure all expected nodes are included in the list.

Select (place checkmark) on all nodes. Click 'Continue'

On the next screen, click 'More Options'

[ ] Add internal CDH parcel repository if needed

2.2	Resolve host inspector issues

If THP shows up:

cat /sys/kernel/mm/transparent_hugepage/defrag always madvise [never]   It should indicate [never] which means it's disabled

vi /etc/rc.local You should see these lines: # Begin Hadoop Configuration parameters echo never > /sys/kernel/mm/transparent_hugepage/defrag 
TODO: Need to edit scripts with RHEL7 version

echo never >  /sys/kernel/mm/transparent_hugepage/defrag

# End Hadoop Configuration parameters

Update VM Swappiness

echo "vm.swappiness = 1" >> /etc/sysctl.conf 	
echo 1 > /proc/sys/vm/swappiness

NOTE: Consider running a DNS caching server (or more than one) inside the cluster for performance reasons.

check for multiple host groups. look for differences and resolve if needed.

Check errors then correct then run host inspector again

2.4	Assign services to hosts

[ ] hdfs blocksize = 128

[ ] failed volumes: half # disks

[ ] Set ZooKeeper root for Kafka to /kafka

[ ] Also checked Enable Kafka Monitoring (Note: Requires Kafka-1.3.0 parcel or higher)

[ ] get hardware specs and fill out the Yarn Tuning guide.

[ ] modify memory overcommit validation threshold if needed


4	Benchmark/Smoketest

4.1	Teragen
```
export HADOOP_USER_NAME=hdfs

hadoop jar /opt/cloudera/parcels/CDH/jars/hadoop-examples.jar teragen -Dmapreduce.job.maps=160 10000000000 /user/hdfs/teragen1TB

hdfs dfs -du -s -h /user/hdfs/teragen1TB

hdfs dfs -rm -r -f -skipTrash /user/hdfs/teragen1TB
```
[ ] look for frame errors
```
[root@ log]# netstat -ina
Kernel Interface table
Iface      MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
eth0      9000 16154899      1      0 0      12845469      0      0      0 BMRU
lo       65536    23065      0      0 0         23065      0      0      0 LRU
```


[ ] get job screen shots for doc


[ ] get CM graphs screen shots for doc 

[ ] Resource Pool Usage

[ ] Cluster CPU/IO/Network

Should see less I/O more network

4.3	Terasort
```
hadoop jar /opt/cloudera/parcels/CDH/jars/hadoop-examples.jar terasort /user/pl75230/teragen1TB /user/pl75230/terasort1TB
```

[ ] get job screen shots for doc

[ ] Resource Pool Usage

[ ] Cluster CPU/IO/Network

[ ] get CM graphs screen shots for doc 

Should see less network more I/O

4.4	TeraValidate
```
hadoop jar /opt/cloudera/parcels/CDH/jars/hadoop-examples.jar teravalidate /user/pl75230/terasort1TB /user/pl75230/teravalidate1TB
```
[ ] get job screen shots for doc

[ ] Resource Pool Usage

[ ] Cluster CPU/IO/Network

[ ] get CM graphs screen shots for doc 



