#!/bin/bash

set -exu

export PGPASSWORD=${PGPASSWORD}

# apps from other packages on this host we need
PSQL=/var/vcap/packages/postgres-9.4/bin/psql

AWSCLI=/var/vcap/packages/awslogs/bin/aws
export LD_LIBRARY_PATH=/var/vcap/packages/awslogs/lib

# get the push gateway ip from toolingbosh
GATEWAY_IP=$(dig +short @${TOOLING_BOSH} ${GATEWAY_HOST})

# build JMESpath filter to exclude a list of instances based on their PrivateIpAddress
query_filter() {
    local IFS
    unset IFS
    local FILTER=""

    for ip in ${1}; do
        if [ -z "$FILTER" ]; then
            FILTER="?PrivateIpAddress != "
        else
            FILTER="${FILTER} && PrivateIpAddress != "
        fi
        FILTER="${FILTER}\`$ip\`"
    done

    echo ${FILTER}
}

# get a list of all the instances bosh has created
KNOWN_INSTANCES=$($PSQL -h ${PGHOST} -U ${PGUSERNAME} -d ${PGDBNAME} -t -c "select uuid from instances")

# find the AWS VPC ID we want to enumerate
VPC_ID=$(${AWSCLI} ec2 describe-vpcs --filter Name=tag:Name,Values=${VPC_NAME} --output text --query 'Vpcs[].VpcId')

# Clear existing metrics from VPC
# See https://github.com/prometheus/pushgateway/issues/117
curl -X DELETE "${GATEWAY_IP}:${PROMETHEUS_PUSH_GATEWAY_PORT:-9091}/metrics/job/bosh_unknown_instance/vpc_name/${VPC_NAME}"

# emit a metric for all instances in that VPC
IFS=$'\n'
for vminfo in $(
        ${AWSCLI} ec2 describe-instances --max-items 1000 --output text  --filter Name=vpc-id,Values=${VPC_ID} --query "
            Reservations[].Instances[$(query_filter "${BOSH_DIRECTOR} ${INSTANCE_WHITELIST}")]
            | [].{\"iaas_id\": InstanceId, \"bosh_id\": Tags[?Key==\`id\`].Value | [0]}
            | [].[iaas_id, bosh_id]"
        )
    do

    iaas_id=$(echo ${vminfo} | cut -f1)
    bosh_id=$(echo ${vminfo} | cut -f2)

    # check to see if bosh director knows about this instance pulled from the iaas
    unknown_instance=0
    if [[ $KNOWN_INSTANCES != *${bosh_id}* ]]; then
        unknown_instance=1
    fi

    cat <<PUSH | curl --data-binary @- "${GATEWAY_IP}:${PROMETHEUS_PUSH_GATEWAY_PORT:-9091}/metrics/job/bosh_unknown_instance/vpc_name/${VPC_NAME}"
    bosh_unknown_iaas_instance {iaas_id="${iaas_id}",bosh_id="${bosh_id}"} ${unknown_instance}
PUSH

done

cat <<PUSH | curl --data-binary @- "${GATEWAY_IP}:${PROMETHEUS_PUSH_GATEWAY_PORT:-9091}/metrics/job/boshunknowninstance-lastcheck/instance/${VPC_NAME}"
bosh_unknown_iaas_instance_lastcheck {vpc_name="${VPC_NAME}"}  $(date +'%s')
PUSH
