#!/usr/bin/env bash

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

source "$SCRIPT_DIR/_helpers.sh"

_info "Accessing working directory"
cd "$PROJECT_ROOT/" || _fail

if [ $CI == true ] && [ ! -z "$AWS_APP_NAME" ] && [ ! -z $ENVIRONMENT ] && [ ! -z $AWS_REGION ]; then
  _info "Get AWS parameter store $AWS_APP_NAME-$ENVIRONMENT and create .env file"
  aws ssm get-parameter --name "$AWS_APP_NAME-$ENVIRONMENT" --with-decryption | jq -r ".Parameter.Value" > .env || _fail
else
  _info "Variables CI=$CI AWS_REGION=$AWS_REGION AWS_APP_NAME=$AWS_APP_NAME ENVIRONMENT=$ENVIRONMENT not defined..."
fi
