#!/bin/bash
#

TARGET='/home/vg/1c_psa_exchange'

SERVICE="$1"

# Yandex VISION
if [ "$SERVICE" != "YANDEX" ]; then
/usr/bin/inotifywait -r -m -e create --format "%w%f" $TARGET \
        | while read FILENAME
                do
                        echo "Detected $FILENAME"
                        /home/vg/bin/pasport_recogn_yandex.sh $FILENAME
                done
fi

# VK VISION
if [  "$SERVICE" != "VK" ]; then
/usr/bin/inotifywait -r -m -e create --format "%w%f" $TARGET \
        | while read FILENAME
                do
                        echo "Detected $FILENAME"
                        /home/vg/bin/pasport_recogn_vk.sh $FILENAME
                done

fi


