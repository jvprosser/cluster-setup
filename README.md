# cluster-setup
`alias jpssh="pssh --timeout=0 --inline-stdout  -h  ~/hostlist.txt -x '-tt' -X '-oStrictHostKeyChecking=no'"`

`alias jpscp="pscp.pssh  -h  ~/hostlist.txt -X '-oStrictHostKeyChecking=no'"`

`export HADOOP_CLASSPATH=/etc/hbase/conf:/opt/cloudera/parcels/CDH/lib/hbase/hbase-common-1.0.0-cdh5.5.0.jar:/opt/cloudera/parcels/CDH/lib/hbase/hbase-server.jar:/opt/cloudera/parcels/CDH/lib/hbase/*:/opt/cloudera/parcels/CDH/lib/hbase/lib/*:/opt/cloudera/parcels/CDH/lib/hbase/cloudera/*:$HADOOP_CLASSPATH`

`export JAVA_HOME=/usr/java/latest `
`export PATH=$JAVA_HOME/bin:$PATH:/usr/local/bin/apache-maven-3.3.9/bin`
