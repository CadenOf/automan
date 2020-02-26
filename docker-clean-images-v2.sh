#!/bin/bash

>/tmp/run_image_ids.$$

DOCKER=/usr/bin/docker
LOG=/var/log/docker-cleanup.log
DAYS=$[ 86400 * 30]

rm /tmp/run_image_ids.$$

echo "$(date) start-----" >>$LOG

$DOCKER ps --no-trunc -a -q | while read cid
do
    running=$($DOCKER inspect -f '{{.State.Running}}' $cid )
    if [ "$running"x = "true"x ]
    then
        id=$($DOCKER inspect -f '{{.Image}}' $cid )
        echo $id >>/tmp/run_image_ids.$$
        continue
    fi 
done

$DOCKER images --no-trunc | grep -v REPOSITORY | awk '{print $3}'| while read image_id
do
    grep -q $image_id /tmp/run_image_ids.$$
    if [ $? -eq 0 ];then
        continue
    fi
    create_time=$($DOCKER inspect -f '{{.Created}}' $image_id | awk -F. '{print $1}')
    diff_time=$(expr $(date +"%s") - $(date --date="$create_time" +"%s"))
    if [ $diff_time -gt $DAYS ];then
        $DOCKER rmi $image_id >>$LOG 2>&1
    fi 
done

rm /tmp/run_image_ids.$$
echo "$(date) end-----" >>$LOG
