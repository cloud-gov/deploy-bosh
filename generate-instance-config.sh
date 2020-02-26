#!/usr/bin/env bash

i=$(aws ec2 describe-instance-types --region us-gov-west-1)
nextToken=$(echo $i | jq -r '.NextToken')
counter=0
echo "$i" > temp-instance-$counter.json

while [[ ${nextToken} != "null" && -n "${nextToken}" ]]; do
    i=$(aws ec2 describe-instance-types --region us-gov-west-1 --next-token $nextToken)
    nextToken=$(echo $i | jq -r '.NextToken')
    counter=$((counter + 1))
    echo "$i" > temp-instance-$counter.json
done

jq -r 'reduce inputs as $i (.; .InstanceTypes += $i.InstanceTypes)' temp-instance-*.json | \
    jq -r '[.InstanceTypes[] | {"name":.InstanceType,"cloud_properties":{"instance_type":.InstanceType}}]' | \
    yq read -

rm temp-instance-*.json