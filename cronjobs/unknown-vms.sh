#!/bin/bash

set -exu

export PGPASSWORD=${PGPASSWORD}

# apps from other packages on this host we need
RIEMANNC=/var/vcap/jobs/riemannc/bin/riemannc

PSQL=/var/vcap/packages/postgres/bin/psql

AWSCLI=/var/vcap/packages/awslogs/bin/aws
export LD_LIBRARY_PATH=/var/vcap/packages/awslogs/lib

# get a list of all the instances bosh has created
KNOWN_INSTANCES=$($PSQL -h ${PGHOST} -U ${PGUSERNAME} -d ${PGDBNAME} -t -c "select uuid from instances")

# build a JMESPath query to exclude hosts on our whitelist
WHITELIST_QUERY=""
for ip in ${INSTANCE_WHITELIST}; do
	if [ -z "$WHITELIST_QUERY" ]; then
		WHITELIST_QUERY="?PrivateIpAddress != "
	else
		WHITELIST_QUERY="${WHITELIST_QUERY} && PrivateIpAddress != "
	fi
	WHITELIST_QUERY="${WHITELIST_QUERY}\`$ip\`"
done
WHITELIST_QUERY="Reservations[].Instances[${WHITELIST_QUERY}] | "

# find the VPC ID we want to enumerate
VPCID=$(${AWSCLI} ec2 describe-vpcs --filter Name=tag:Name,Values=${VPC_NAME} --output text --query 'Vpcs[].VpcId')

# find all instances in that VPC and emit a metric for each unknown host
for id in $(${AWSCLI} ec2 describe-instances --max-items 500 --output text  --filter Name=vpc-id,Values=${VPCID} --query "${WHITELIST_QUERY} [].{\"aws_id\": InstanceId, \"bosh_id\": Tags[?Key==\`id\`].Value | [0]} | [].[bosh_id || aws_id]"); do
	STATE="ok"

	if [[ $KNOWN_INSTANCES != *${id}* ]]; then
		STATE="critical"
	fi

    ${RIEMANNC} --service "unknown-vm.found" --host ${id} --state ${STATE} --ttl 120 --metric_sint64 1
done

${RIEMANNC} --service "unknown-vm.check" --host $(hostname) --ttl 300 --metric_sint64 1
