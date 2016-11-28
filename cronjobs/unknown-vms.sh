#!/bin/bash

set -exu

export PGPASSWORD=${PGPASSWORD}

# apps from other packages on this host we need
RIEMANNC=/var/vcap/jobs/riemannc/bin/riemannc

PSQL=/var/vcap/packages/postgres/bin/psql

AWSCLI=/var/vcap/packages/awslogs/bin/aws
export LD_LIBRARY_PATH=/var/vcap/packages/awslogs/lib

#function to build JMESpath query to exclude certain hosts based on ip
query_filter() {
    local IFS
    unset IFS
    local QUERY=""

    for ip in ${1}; do
        if [ -z "$QUERY" ]; then
            QUERY="?PrivateIpAddress != "
        else
            QUERY="${QUERY} && PrivateIpAddress != "
        fi
        QUERY="${QUERY}\`$ip\`"
    done

    QUERY="Reservations[].Instances[${QUERY}] | "

    echo ${QUERY}
}

# get a list of all the instances bosh has created
KNOWN_INSTANCES=$($PSQL -h ${PGHOST} -U ${PGUSERNAME} -d ${PGDBNAME} -t -c "select uuid from instances")

# find the VPC ID we want to enumerate
VPCID=$(${AWSCLI} ec2 describe-vpcs --filter Name=tag:Name,Values=${VPC_NAME} --output text --query 'Vpcs[].VpcId')

# find all instances in that VPC and emit a metric for each unknown host
for id in $(${AWSCLI} ec2 describe-instances --max-items 500 --output text  --filter Name=vpc-id,Values=${VPCID} --query "$(query_filter "${BOSH_DIRECTOR} ${INSTANCE_WHITELIST}") [].{\"aws_id\": InstanceId, \"bosh_id\": Tags[?Key==\`id\`].Value | [0]} | [].[bosh_id || aws_id]"); do
    STATE="ok"

    if [[ $KNOWN_INSTANCES != *${id}* ]]; then
        STATE="critical"
    fi

    ${RIEMANNC} --service "unknown-vm.found" --host ${id} --state ${STATE} --ttl 120 --metric_sint64 1
done

# emit metrics with bosh id, iaas id, and uptime info for all non-whitelisted VMs
IFS=$'\n'
for vminfo in $(${AWSCLI} ec2 describe-instances --max-items 500 --output text  --filter Name=vpc-id,Values=${VPCID} --query "$(query_filter "${INSTANCE_WHITELIST}") [].{\"launch\": LaunchTime, \"aws_id\": InstanceId, \"bosh_id\": Tags[?Key==\`id\`].Value | [0]} | [].[bosh_id, aws_id, launch]"); do

    bosh_id=$(echo ${vminfo} | cut -f1)
    aws_id=$(echo ${vminfo} | cut -f2)
    launch=$(echo ${vminfo} | cut -f3)

    ${RIEMANNC} --service "aws.ec2.describe-instances" --host ${aws_id} --attributes bosh_id=${bosh_id} --ttl 120 --metric_sint64 $(($(date +%s) - $(date -d"${launch}" +%s)))
done

${RIEMANNC} --service "unknown-vm.check" --host $(hostname) --ttl 300 --metric_sint64 1
