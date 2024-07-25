#!/bin/bash
#
# Yandex auth token
IAM_TOKEN=`cat /etc/iamtoken.txt`
COMPRESS_CMD='/usr/bin/convert -strip -resize 50% -interlace Plane -gaussian-blur 0.05 -quality 85%'

if [ ! -z "`echo $1 | grep -E 'filepart|pdf|PDF'`" ]; then
        echo "exit"
        exit 1;
fi

if [ -z "`echo $1 | grep -E 'jpg|JPG|jpeg|JPEG'`" ]; then
        echo "exit"
        exit 1;
fi


OUT_DIR='/home/vg/1c_psa_exchange'

sleep 1

# Waiting upload
/usr/bin/timeout 60 /usr/bin/inotifywait -q -q -e close "$1"

# Random string
RAND=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`

# Image size
IMAGE_SIZE=`du -b "$1" | awk '{print $1}'`
echo $IMAGE_SIZE

# Compressing image if more then 2M
if [ "$IMAGE_SIZE" -gt "2097152" ]; then
    $COMPRESS_CMD "$1" "/tmp/image_${RAND}"

# Replacing image in storage
mv "/tmp/image_${RAND}" "$1"
fi

# Passport image
PS_IMG="`base64 -w 0 -i $1`"

# Date
DATE=`date "+%d-%m-%Y-%H%M"`

FILE_NAME="`basename "$1" | awk -F '.' '{print $1}'`"

RND=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`

# Yandex request
body_data() {
cat << EOF
{
    "folderId": "b1gtqbe938v0k1f59vfr",
    "analyze_specs": [{
        "content": "$PS_IMG",
        "features": [{
            "type": "TEXT_DETECTION",
            "text_detection_config": {
                "language_codes": ["ru"],
                "model": "passport"
            }
        }]
    }]
}

EOF
}
UUID=`/usr/bin/uuidgen`
echo $UUID > /tmp/uuid_${DATE}_${RND}.txt
body_data > /tmp/passport_${DATE}_${RND}.json

# Sending request
curl -s -X POST \
    -H "x-client-request-id: $UUID" \
    -H "x-data-logging-enabled: true" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${IAM_TOKEN}" \
    -d @"/tmp/passport_${DATE}_${RND}.json"  \
     https://vision.api.cloud.yandex.net/vision/v1/batchAnalyze > /tmp/output_${DATE}_${RND}.json


# ПОЛ:
#gender="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep -A 1 gender | tail -1 | sed 's/\"text\"/gender/g'`"
#if [ ! -z "$gender" ]; then
#	echo $gender > $OUT_DIR/"${FILE_NAME}".txt
#else
#	echo "gender is NULL" > $OUT_DIR/"${FILE_NAME}".txt
#fi

# Код подразделения
#subdivision="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep subdivision -A 1 | tail -1 | sed 's/\"text\"/subdivision/g'`"
#if [ ! -z "$subdivision" ]; then
#        echo $subdivision >> $OUT_DIR/"${FILE_NAME}".txt
#else
#        echo "subdivision is NULL" >> $OUT_DIR/"${FILE_NAME}".txt
#fi

# Дата рождения
#birth_date="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep birth_date -A 1 | tail -1 | sed 's/\"text\"/birth_date/g'`"
#if [ ! -z "$birth_date" ]; then
#        echo $birth_date >> $OUT_DIR/"${FILE_NAME}".txt
#else
#        echo "birth_date is NULL" >> $OUT_DIR/"${FILE_NAME}".txt
#fi

# Место рождения
#birth_place="`cat /tmp/output_${DATE}_${RND}.json |jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep birth_place -A 1 | tail -1 | sed 's/\"text\"/birth_place/g' | sed -e "s/\b\(.\)/\u\1/g"`"
#if [ ! -z "$birth_place" ]; then
#        echo $birth_place >> $OUT_DIR/"${FILE_NAME}".txt
#else
#        echo "birth_place is NULL" >> $OUT_DIR/"${FILE_NAME}".txt
#fi

# Серия и номер паспорта
number="`cat /tmp/output_${DATE}_${RND}.json |jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep number -A 1 | tail -1 |  awk -F '"' '{print $4}' | sed 's/..../& /'`"
if [ -z "$number" ]; then
        number="NULL"
fi

# Выдан
issuedby="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep issued_by -A 1 | tail -1 |  awk -F '"' '{print $4}' | sed -e 's/\(.*\)/\U\1/'`"
if [ -z "$issuedby" ]; then
	issuedby="NULL"
fi

# Дата выдачи
issue_date="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep issue_date -A 1 | tail -1 |  awk -F '"' '{print $4}' | sed -e "s/\b\(.\)/\u\1/g"`"
if [ -z "$issue_date" ]; then
       issue_date="NULL"
fi

# Фамилия
surname="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep surname -A 1 | tail -1 |  awk -F '"' '{print $4}' | sed -e "s/\b\(.\)/\u\1/g"`"
if [ -z "$surname" ]; then
       surname="NULL"
fi


# Имя
name="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep '"name": "name",' -A 1 | tail -1 |  awk -F '"' '{print $4}' | sed -e "s/\b\(.\)/\u\1/g"`"
if [ -z "$name" ]; then
       name="NULL"
fi


# Отчество
middle_name="`cat /tmp/output_${DATE}_${RND}.json | jq '.results[] .results[] .textDetection.pages[] .entities[]' | grep middle_name -A 1 | tail -1 |  awk -F '"' '{print $4}' | sed -e "s/\b\(.\)/\u\1/g"`"
if [ -z "$middle_name" ]; then
       middle_name="NULL"
fi

echo "pasport: 'Паспорт: ${number} выдан: ${issue_date} ${issuedby}'" > $OUT_DIR/"${FILE_NAME}".txt
echo "partner: '${surname} ${name} ${middle_name}'" >> $OUT_DIR/"${FILE_NAME}".txt

# Clean
rm /tmp/output_${DATE}_${RND}.json
#rm /tmp/passport_${DATE}_${RND}.json
