#!/bin/sh

CURL=/usr/bin/curl
LOGGER=/usr/bin/logger
ECHO=/bin/echo
CUT=/bin/cut
AWS=/root/.local/bin/aws
GREP=/bin/grep
AWK=/bin/awk
WC=/usr/bin/wc
SORT=/bin/sort
DATE=/bin/date
EXPR=/usr/bin/expr

SNAPSHOT_GEN=2
DATE=`date +%Y%m%d-%H%M`
SNAPSHOT_NAME="dev-tcz-${DATE}"

log(){
    local product_name pid level msg
    if [ $# -eq 2 ]; then
        product_name=${0##*/}
        pid=$$
        level=$1
        msg=$2
    
        if [ "${level}" = "ERR" ] ; then  
            ${LOGGER} -t "${level}" "=== ERROR === : ${product_name}[${pid}] ${msg}"
        else
            ${LOGGER} -t "${level}" "${product_name}[${pid}] ${msg}"
        fi
    fi
}

create_snapshot() {
    log "INFO" "Start create snapshot for AWS_EBS:Volume ${VOL_ID}"
    ${AWS} --region ${REGION} ec2 create-snapshot --volume-id ${VOL_ID} --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=${SNAPSHOT_NAME}}]" --description "Created by Daily backup(${INSTANCE_ID}) from ${VOL_ID}" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        log "ERR" "ec2-create-snapshot failed AWS_EBS:Volume ${VOL_ID} [202]"
        exit 202
    fi
    log "INFO" "End create snapshot for AWS_EBS:Volume ${VOL_ID}"
}

delete_snapshot() {
    local cnt=0

    log "INFO" "Start delete snapshot AWS_EBS:Volume ${VOL_ID}"
    
    SNAPSHOTS=`${AWS} --region ${REGION} ec2 describe-snapshots --filters Name=volume-id,Values=${VOL_ID} --output text | ${GREP} 'Created by Daily backup' | ${SORT} -k12 -r | ${AWK} '{print $11}'`
    
    for SNAPSHOT in ${SNAPSHOTS}; do
        if [ ${cnt} -ge ${SNAPSHOT_GEN} ]; then
            ${AWS} --region ${REGION} ec2 delete-snapshot --snapshot-id ${SNAPSHOT} && log "INFO" "ec2-delete-snapshot : ${SNAPSHOT}"
        fi
        cnt=`${EXPR} ${cnt} + 1`
    done
    
    log "INFO" "End delete snapshot AWS_EBS:Volume ${VOL_ID}"
}

log "INFO" "Script is START."

AZ=`${CURL} -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
LN=`${ECHO} $((${#AZ} - 1))`
REGION=`${ECHO} ${AZ} | ${CUT} -c 1-${LN}`
INSTANCE_ID=`${CURL} -s http://169.254.169.254/latest/meta-data/instance-id`

VOL_IDS=`${AWS} --region ${REGION} ec2 describe-instances --instance-ids ${INSTANCE_ID} --output text | ${GREP} '^EBS' | ${AWK} '{print $5}'`

for VOL_ID in ${VOL_IDS}; do
    create_snapshot
done

for VOL_ID in ${VOL_IDS}; do
    delete_snapshot
done

log "INFO" "Script is END."

exit 0

