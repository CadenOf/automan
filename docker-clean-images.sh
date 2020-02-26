#!/bin/sh

ONEHOUR=3600
let OUTTIME=(12 * $ONEHOUR)

echo $OUTTIME
image_list=`docker images |grep -v REPOSITORY |awk '{print $3}'|tr "\n" " "`
for i in $image_list
do
    created_date=`docker inspect -f '{{ .Created }}' $i`
    created_timestamp=`date -d "$created_date" +%s`
    current_timestamp=`date +%s`
    let delta=($current_timestamp - $created_timestamp)
    if [ $delta -ge $OUTTIME ];then                                                                                                                                                      
        echo $i
        docker rmi -f $i
    fi  
done
