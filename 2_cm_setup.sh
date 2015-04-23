#!/bin/bash


pscp --timeout=0 -h  hostlist.txt -l ec2-user  -X '-oStrictHostKeyChecking=no'  2_target_setup.sh /tmp/2_target_setup.sh
pscp --timeout=0 -h  hostlist.txt -l ec2-user  -X '-oStrictHostKeyChecking=no'  etc.hosts /tmp/etc.hosts
pscp --timeout=0 -h  hostlist.txt -l ec2-user  -X '-oStrictHostKeyChecking=no'  jdk-7u51-linux-x64.rpm  /tmp/

pssh --timeout=0 --inline-stdout  -t 0 -h  hostlist.txt -l ec2-user -x '-tt' -X '-oStrictHostKeyChecking=no'  'sudo bash -x -c "/tmp/2_target_setup.sh"'


