#!/bin/bash
#
COMPRESS_CMD='/usr/bin/convert -strip -resize 50% -interlace Plane -gaussian-blur 0.05 -quality 85%'
VK_TOKEN='LnsbCR1z8BUzqc8ejifUEk8GWz4JbjbiTfJKPpz7XohyQR1nF'

if [ ! -z "`echo $1 | grep -E 'filepart|pdf|PDF'`" ]; then
        echo "exit"
        exit 1;
fi

if [ -z "`echo $1 | grep -E 'jpg|JPG|jpeg|JPEG'`" ]; then
        echo "exit"
        exit 1;
fi


OUT_DIR='/home/vg/1c_psa_exchange'

# Date
DATE=`/usr/bin/date "+%d-%m-%Y-%H%M"`

echo $DATE
sleep 1

# Waiting upload
/usr/bin/timeout 10 /usr/bin/inotifywait -q -q -e close "$1"

# Random string
RND=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`

RAND=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`

# Image size
IMAGE_SIZE=`du -b "$1" | awk '{print $1}'`

echo "Image size: $IMAGE_SIZE"

# Compressing image if more then 2M
if [ "$IMAGE_SIZE" -gt "2097152" ]; then
    $COMPRESS_CMD "$1" "/tmp/image_${RAND}"

# Replacing image in storage
mv "/tmp/image_${RAND}" "$1"
fi

curl -s \
  "https://smarty.mail.ru/api/v1/docs/recognize?oauth_token=$VK_TOKEN&oauth_provider=mcs" \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F "file=@$1;type=image/jpeg" \
  -F 'meta={
  "images": [
    {
      "name": "file"
    }
  ]
}' -o /tmp/output_${DATE}_${RND}.json


FILE_NAME="`basename "$1" | awk -F '.' '{print $1}'`"

# Серия и номер паспорта
number="`cat /tmp/output_${DATE}_${RND}.json | jq '.body.objects[] .labels.code_of_issue[]' |  sed 's/\"//g'`"

if [ -z "$number" ]; then
        number="NULL"
fi

# Выдан
issuedby="`cat /tmp/output_${DATE}_${RND}.json | jq '.body.objects[] .labels.place_of_issue[]' | tr "\n" " " |  sed 's/\"//g'`"

if [ -z "$issuedby" ]; then
	issuedby="NULL"
fi

# Дата выдачи
issue_date="`cat /tmp/output_${DATE}_${RND}.json | jq '.body.objects[] .labels.date_of_issue[]' |  sed 's/\"//g'`"
if [ -z "$issue_date" ]; then
       issue_date="NULL"
fi

# Фамилия
surname="`cat /tmp/output_${DATE}_${RND}.json | jq '.body.objects[] .labels.last_name[]' |  sed 's/\"//g'`"
if [ -z "$surname" ]; then
       surname="NULL"
fi


# Имя
name="`cat /tmp/output_${DATE}_${RND}.json | jq '.body.objects[] .labels.first_name[]' |  sed 's/\"//g'`"
if [ -z "$name" ]; then
       name="NULL"
fi


# Отчество
middle_name="`cat /tmp/output_${DATE}_${RND}.json |  jq '.body.objects[] .labels.middle_name[]' |  sed 's/\"//g'`"
if [ -z "$middle_name" ]; then
       middle_name="NULL"
fi

echo "pasport: 'Паспорт: ${number} выдан: ${issue_date} ${issuedby}'" > $OUT_DIR/"${FILE_NAME}".txt
echo "partner: '${surname} ${name} ${middle_name}'" >> $OUT_DIR/"${FILE_NAME}".txt

# Clean
rm /tmp/output_${DATE}_${RND}.json
