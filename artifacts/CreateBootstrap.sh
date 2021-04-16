#!/bin/sh
aws cloudformation create-stack --stack-name OpenShiftBootstrapNode --parameters file://BootstrapParams.json --template-body file://BootstrapTemplate.yaml --capabilities CAPABILITY_NAMED_IAM
while true; do aws cloudformation describe-stacks --stack-name OpenShiftBootstrapNode; sleep 5; done