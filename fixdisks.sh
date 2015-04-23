#!/bin/bash                                                                                         

sed -i -e '/kernel /s/$/ rd_NO_LUKS/' /etc/grub.conf
mv /tmp/lukskey.bin /root

