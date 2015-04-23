#!/bin/bash




dd if=/dev/urandom of=/root/lukskey.bin bs=4k count=1

# s3cmd put /root/lukskey.bin s3://hackaround/


pscp  -h  hostlist.txt -l ec2-user  -X '-oStrictHostKeyChecking=no'  ./lukskey.bin  /tmp/lukskey.bin

pscp  -h  hostlist.txt -l ec2-user  -X '-oStrictHostKeyChecking=no'  ./3_target_luksdodisk.sh  /tmp/

pssh --inline-stdout  -t 0 -h  hostlist.txt -l ec2-user -x '-tt' -X '-oStrictHostKeyChecking=no'  'sudo bash -x -c "/tmp/3_target_luksdodisk.sh"'



