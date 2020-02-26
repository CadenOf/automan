#!/bin/bash

DUMP=/usr/local/mysql/bin/mysqldump
D_TIME=`date +%Y-%m-%d-%H%M%S`
D_PATH=/opt/mysql-dump/data_bak
S_DATABASE="your_data_base"
D_DATABASE=${S_DATABASE}-${D_TIME}
KEEP_COUNT=10

if [ ! -d "${D_PATH}" ]; then
  echo ${D_PATH}
  mkdir -p ${D_PATH}
fi

$DUMP -uroot -p'password' ${S_DATABASE} > ${D_PATH}/${D_DATABASE}.sql

SQL_COUNT=`ls ${D_PATH}|grep sql -c`

if [ $SQL_COUNT -gt $KEEP_COUNT ];then
    echo $SQL_COUNT
    find ${D_PATH} -name "*.sql" -type f -mtime +${KEEP_COUNT} -exec rm -f {} \;
fi

