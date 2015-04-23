#!/bin/bash
#############################################
# 5) Un-mount /mnt mounting point and remove it from fstab.
# 6) Go through all the different drives, create the FS and mount them
#############################################

#############################################
# Distribution automatic detection
echo "RUNNING luks version of dodisk!!"

echo Distribution detection > /tmp/init_script.log
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
  echo Create, encrypt and mount $i >> init_script.log

  echo Create partition on /dev/$i >> init_script.log
  (echo o; echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/$i &>> init_script.err

  echo Encrypt file system on /dev/${i}${one} >> init_script.log
  echo "YES" | cryptsetup -y luksFormat /dev/${i}${one} --key-file /tmp/lukskey.bin

  echo "create device mapping for dev/$i$one called enc_${i}${one} " >> init_script.log
  cryptsetup luksOpen /dev/$i$one enc_${i}${one}  --key-file /tmp/lukskey.bin

  echo Create file system on /dev/mapper/enc_${i}${one}  >> init_script.log
  mkfs.ext4 -m 0 /dev/mapper/enc_${i}${one} &>> init_script.err

  echo "tell dracut not to automount since we don't have console access on s3" >> init_script.log
  sed -i -e '/kernel /s/$/ rd_NO_LUKS/' /etc/grub.conf
  
  echo Create mount point for /dev/mapper/enc_${i}${one} in /data/$counter >> init_script.log
  mkdir -p /data/$counter  >> init_script.err

#  echo Update of fstab script  >> init_script.log
#  mountline="/dev/${i}${one} /data/$counter ext4 noatime 0 0"
#  sh -c "echo $mountline >> /etc/fstab" >> init_script.err

  sudo mount /dev/mapper/enc_${i}${one}  /data/$counter >> init_script.log

  sudo echo  -e "\ncryptsetup luksOpen /dev/$i$one enc_${i}${one}  --key-file /root/lukskey.bin" >> /etc/rc.local
  sudo echo  -e "\n  mount /dev/mapper/enc_${i}${one}  /data/$counter >> init_script.log" >> /etc/rc.local

  counter=`expr $counter + 1`

done

mv /tmp/lukskey.bin /root
mount -a
#############################################

