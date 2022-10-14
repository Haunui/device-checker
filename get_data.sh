#!/usr/bin/bash

DEVICE="/dev/prod/http"
DEVICE_MP="/srv/http"

PREFIX="[$DEVICE]"

log_std() {
        echo "$PREFIX $1"
        logger "$PREFIX $1"
}

O=0
C=0
while [ $O -eq 0 ]; do
        if mount | grep "$DEVICE_MP" &> /dev/null; then
                O=1
                logger "$PREFIX $DEVICE already mount, ignored."
                continue
        else
                UUID=$(cat /etc/fstab | grep -v "^#" | grep "/mnt/usb" | awk '{print $1}' | cut -d"=" -f2 | tr -d '\n')
                MOUNT_PATH=$(cat /etc/fstab | grep -v "^#" | grep "/mnt/usb" | awk '{print $2}' | tr -d '\n')

                if blkid | grep "UUID=\"$UUID\"" &> /dev/null; then
                        mount UUID=$UUID $MOUNT_PATH &> /dev/null
                        cryptsetup luksOpen UUID=31cc8204-4fba-4b27-bd4a-af7abeeddef7 data --key-file $MOUNT_PATH/keyfile &> /dev/null
                        R=$?
                        if [ $R -eq 0 ] || [ $R -eq 5 ]; then
                                mount "$DEVICE" "$DEVICE_MP" &> /dev/null
                                O=1

                                if [ $R -eq 5 ]; then
                                        log_std "Encrypted device is already readable"
                                        log_std "encrypted device is now mounted"
                                else
                                        log_std "encrypted device is now readable and mounted"
                                fi

                                continue
                        else
                                log_std "Wrong keyfile"
                        fi

                        umount $MOUNT_PATH &> /dev/null
                fi

                if [ $C -ge 10 ]; then
                        log_std "Waiting for keyfile"
                        C=0
                fi

                C=$(($C+1))
                sleep 3
        fi
done
