#!/usr/bin/env bash

# Variables
ENVIRONMENT=""
INSTANCE_TAG_SUFFIX=""
PORT_NUMBER=""
LOCAL_PORT_NUMBER=""
AWS_DEFAULT_REGION=""
AWS_PROFILE=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --environment)
        ENVIRONMENT="$2"
        shift
        shift
        ;;
    --region)
        AWS_DEFAULT_REGION="$2"
        shift
        shift
        ;;
    --aws-profile)
        AWS_PROFILE="$2"
        shift
        shift
        ;;
    --instance-tag-suffix)
        INSTANCE_TAG_SUFFIX="$2"
        shift
        shift
        ;;
    --port-number)
        PORT_NUMBER="$2"
        shift
        shift
        ;;
    --local-port-number)
        LOCAL_PORT_NUMBER="$2"
        shift
        shift
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

# Check if all required arguments are provided
if [[ -z $ENVIRONMENT || -z $INSTANCE_TAG_SUFFIX || -z $PORT_NUMBER || -z $LOCAL_PORT_NUMBER || -z $AWS_DEFAULT_REGION ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 --environment <value> --region <value> --aws-profile <value> --instance-tag-suffix <value> --port-number <value> --local-port-number <value>"
    exit 1
fi

aws_options=(--profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION")

INSTANCE_ID=$(aws "${aws_options[@]}" ec2 describe-instances \
    --filters \
    Name=tag:Name,Values="${ENVIRONMENT}${INSTANCE_TAG_SUFFIX}" \
    Name=instance-state-name,Values=running \
    --query 'Reservations[*].Instances[*].[InstanceId]' --output text)

aws "${aws_options[@]}" ssm start-session --target "$INSTANCE_ID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters "{\"portNumber\":[\"$PORT_NUMBER\"], \"localPortNumber\":[\"$LOCAL_PORT_NUMBER\"]}"
