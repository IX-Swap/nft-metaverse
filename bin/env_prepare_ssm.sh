#!/usr/bin/env bash

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

source "$SCRIPT_DIR/_helpers.sh"

_info "Accessing working directory"
cd "$PROJECT_ROOT/" || _fail

_info "Get Environment varibles from Parameter Store AWS_SSM_ENV_NAME=$AWS_SSM_ENV_NAME"   # diversifi-app-web-production-env
aws ssm get-parameters --names "$AWS_SSM_ENV_NAME"  --with-decryption  --query "Parameters[].{Name: Name, Value: Value}" >> /dev/null || _fail
aws ssm get-parameters --names "$AWS_SSM_ENV_NAME"  --with-decryption  --query "Parameters[].{Name: Name, Value: Value}" | jq -r '.[].Value' > .env || _fail

if [ ! -z $NODE_ENV ]; then
    cp -v .env .env.$NODE_ENV
elif [ ! -z $ENVIRONMENT ]; then
    cp -v .env .env.$ENVIRONMENT
fi