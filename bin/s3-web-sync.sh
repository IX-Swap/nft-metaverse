#!/usr/bin/env bash

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

source "$SCRIPT_DIR/_helpers.sh"

_info "Accessing working directory"
cd "$PROJECT_ROOT/" || _fail

# _info "Loading .env configuration"
# source $(_env_file "prod") || _fail
#
# _info "Exporting TF_VAR_*"
# declare -a ENV_VARS=( "AWS_REGION" "AWS_APP_NAME" "ENVIRONMENT" )
#
# for _var in ${ENV_VARS[@]}; do
#   echo "export ${_var}=${!_var}"
#   export "${_var}=${!_var}"
# done
#
# if [ -z "${ENVIRONMENT}" ] | [ -z "${AWS_APP_NAME}" ]; then
#   _info "Check .env file"
#   if [ -f .env ]; then
#     source .env
#   fi
# fi

_info "ENVIRONMENT and AWS_APP_NAME"
if [ -z "${ENVIRONMENT}" ] | [ -z "${AWS_APP_NAME}" ]; then
  _fail ' ENVIRONMENT is null !!! '
else
  cd ./terraform
  _info "Manage terrafom env workspace"
  _tf_workspace  || _fail
  terraform output
  _info 'Wait SYNC files with AWS S3 Bucket'
  bucket_name=$(terraform output s3_bucket_id) || _fail
  echo bucket_name=$bucket_name
#   aws s3 sync ../images/ s3://${bucket_name}/images/ --acl public-read --delete || _fail
  aws s3 sync ../images/ s3://${bucket_name}/images/ --acl public-read --content-type image/png --delete || _fail
  aws s3 sync ../metadata/ s3://${bucket_name}/metadata/ --acl public-read --content-type application/json --delete || _fail
  _info 'Activate S3 bucket versioning'
  aws s3api put-bucket-versioning --bucket ${bucket_name} --versioning-configuration Status=Enabled || _fail
#   _info 'Set index.html main document file'
#   aws s3 website s3://${bucket_name}/ --index-document index.html || _fail
  _info 'invalidate cloudfront cache invalidation'
  aws cloudfront create-invalidation --distribution-id $(terraform output cf_id) --paths "/*" >> /dev/null || _fail
fi

