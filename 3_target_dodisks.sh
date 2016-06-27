#!/bin/bash
#############################################
# 5) Un-mount /mnt mounting point and remove it from fstab.
# 6) Go through all the different drives, create the FS and mount them
#############################################

#############################################
# Distribution automatic detection
echo Distribution detectoin > /tmp/init_script.log
REDHAT=false
DEBIAN=false
if [ -f /etc/redhat-release ]; then REDHAT=true; fi
if [ -f /etc/os-release ]; then DEBIAN=true; fi
if $REDHAT; then
  echo RedHat detected >> /tmp/init_script.log
fi
if $DEBIAN; then
  echo Debian/Ubuntu detected >> /tmp/init_script.log
fi
if ((! $REDHAT && ! $DEBIAN) || ($REDHAT && $DEBIAN)); then 
  echo Impossible to identify linux distribution. >> /tmp/init_script.log
  echo Please check and adjust the script. >> /tmp/init_script.log
  #exit
fi
#############################################

#############################################
# (RedHat) Un-mount /mnt mounting point and remove it from fstab.
if $REDHAT; then
  echo Clear already mounted drive >> /tmp/init_script.log
  umount /mnt
  cat /etc/fstab | grep -v "/mnt" > /tmp/fstab.new
  mv /tmp/fstab.new /etc/fstab
fi

# (Ubuntu) Un-mount /mnt mounting point and remove it from fstab. 
if $DEBIAN; then
  echo Clear already mounted drive >> /tmp/init_script.log
  umount /mnt
  cat /etc/fstab | grep -v "/mnt" > /tmp/fstab.new
  mv /tmp/fstab.new /etc/fstab
fi
#############################################

#############################################
# Go through all the different drives, create the FS and mount them
echo Create and mount all available block devices. >> init_script.log
counter=1
one=1
for i in `ls /dev/xvd[b-z] | cut -d"/" -f3`; do
  echo Create and mount $i >> init_script.log
  echo Create partition on /dev/$i >> init_script.log
  (echo o; echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/$i &>> init_script.err
  echo Create file system on /dev/$i$one >> init_script.log
  mkfs.ext4 -m 0 /dev/$i$one &>> init_script.err
  echo Create mount point /dev/$i$one in /data/$counter >> init_script.log
  mkdir -p /data/$counter  >> init_script.err
  echo Update of fstab script  >> init_script.log
  mountline="/dev/$i$one /data/$counter ext4 noatime 0 0"
  sh -c "echo $mountline >> /etc/fstab" >> init_script.err
  counter=`expr $counter + 1`
done
mount -a
#############################################
# Generate a list of dfs data disks. grepping for hadoop may not be appropriate.
df –h  | grep hadoop | awk '{print $1}'  >resize.txt   
for i in `cat resize.txt`;do 
# -m reserved-blocks-percentage - recovers %5 disk
tune2fs -m 0 $i
# -c max-mount-counts disable auto filesystem check - so fsck will never get run automatically after N mounts/reboots.
tune2fs -c 0 $i
done
