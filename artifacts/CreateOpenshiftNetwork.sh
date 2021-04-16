#!/bin/sh
aws cloudformation create-stack --stack-name OpenShiftNetwork --template-body file://NetworkTemplate.yaml --parameters file://NetworkParams.json --capabilities CAPABILITY_NAMED_IAM
while true; do aws cloudformation describe-stacks --stack-name OpenShiftNetwork; sleep 5; done