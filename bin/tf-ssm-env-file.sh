#!/usr/bin/env bash

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

source "$SCRIPT_DIR/_helpers.sh"

_info "Accessing working directory"
cd "$PROJECT_ROOT/" || _fail

_info "Loading .env configuration"
source $(_env_file "prod") || _fail

_info "Exporting TF_VAR_*"
declare -a ENV_VARS=( "AWS_REGION" "AWS_APP_NAME" "ENVIRONMENT" )

for _var in ${ENV_VARS[@]}; do
  echo "export TF_VAR_${_var}=${!_var}"
  export "TF_VAR_${_var}=${!_var}"
done

if [ $CI == true ] && [ ! -z "$AWS_APP_NAME" ] && [ ! -z $ENVIRONMENT ] && [ ! -z $AWS_REGION ]; then
  _info "Get AWS parameter store $AWS_APP_NAME-$ENVIRONMENT and create .env file"
  aws ssm get-parameter --name "$AWS_APP_NAME-$ENVIRONMENT" --with-decryption | jq -r ".Parameter.Value" > .env || _fail
else
  _info "Variables AWS_REGION AWS_APP_NAME ENVIRONMENT not defined..."
fi
