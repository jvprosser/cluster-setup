#!/bin/bash


jpscp 2_target_setup.sh /tmp/2_target_setup.sh

jpssh 'wget https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo;mv cloudera-manager.repo /etc/yum.repos.d/'
jpssh yum -y install oracle-j2sdk1.7

jpssh ln -s /usr/java/jdk1.7.0_67-cloudera/ /usr/java/latest
jpscp mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar /tmp
jpssh mkdir -p /usr/share/java
jpssh cp /tmp/mysql-connector-java-5.1.38-bin.jar /usr/share/java/mysql-connector-java.jar

jpssh mv /usr/java/latest/jre/lib/security/US_export_policy.jar /usr/java/jdk1.7.0_67-cloudera/jre/lib/security/ORIG_US_export_policy.jar

jpssh mv /usr/java/latest/jre/lib/security/local_policy.jar /usr/java/latest/jre/lib/security/ORIG_local_policy.jar

jpscp  UnlimitedJCEPolicy/*  /usr/java/latest/jre/lib/security/
jpssh  'bash -x -c "/tmp/2_target_setup.sh"'


