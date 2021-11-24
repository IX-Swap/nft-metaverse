#!/usr/bin/env bash

AUTHORIZED_KEYS_FILE='~/.ssh/authorized_keys'
GITLAB_HOST="gitlab.titanium.codes"
SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

source "$SCRIPT_DIR/_helpers.sh"

if [[ "$1" == "dev"* || "$1" == "staging" ]]; then
  ENVIRONMENT=$1
  source .env.$ENVIRONMENT
else
  _fail 'environment does not specified, example ./bin/gitlab-configure.sh dev'
  exit 100
fi

_info "Setup DOTENV_CONTENT variable"
if [[ ! -z "$ONLY_STAGING" || $ENVIRONMENT == "staging" ]]; then
    DOTENV_CONTENT="STAGING_DOTENV_CONTENT" && echo DOTENV_CONTENT=$DOTENV_CONTENT
elif [[ ! -z "$ONLY_DEV" || $ENVIRONMENT == "dev"* ]]; then
    DOTENV_CONTENT="DEV_DOTENV_CONTENT" && echo DOTENV_CONTENT=$DOTENV_CONTENT
else
  _fail 'No one of variables found: ONLY_STAGING / ONLY_DEV / ENVIRONMENT'
fi

if [ -z "$ACCESS_TOKEN" ]; then
  _fail "Missing Gitlab ACCESS_TOKEN"
elif [ -z "$PROJECT_ID" ]; then
  _fail "Missing Gitlab PROJECT_ID (e.g. 324)"
elif [ -z "$DOMAIN" ]; then
  _fail "Missing DOMAIN (e.g. www.example.com)"
elif [ -z "$DEPLOY_SERVER_DSN" ]; then
  _fail "Missing DEPLOY_SERVER_DSN (e.g. root@138.68.83.144)"
fi

function create_var() {
  echo "[CREATE] [$ENVIRONMENT] $1 >> `curl -w "%{http_code}" --silent --request POST --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "https://$GITLAB_HOST/api/v4/projects/$PROJECT_ID/variables" --form "key=$1" --form "environment_scope=$ENVIRONMENT" --form "value=$2" -o /dev/null`"
}

function create_var_file() {
  echo "[CREATE] [$ENVIRONMENT] $1 >> `curl -w "%{http_code}" --silent --request POST --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "https://$GITLAB_HOST/api/v4/projects/$PROJECT_ID/variables" --form "key=$1" --form "environment_scope=$ENVIRONMENT" --form "variable_type=file" --form "value=$2" -o /dev/null`"
}

function delete_var() {
  echo "[DELETE] [$ENVIRONMENT] $1 >> `curl -w "%{http_code}" --silent --request DELETE --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "https://$GITLAB_HOST/api/v4/projects/$PROJECT_ID/variables/$1?filter[environment_scope]=$ENVIRONMENT" -o /dev/null`"
}

function _env_file() {
  local _efile="$PROJECT_ROOT/.env.$1"
  if [ -f "$_efile" ]; then
    echo "$_efile"
  else
    echo "$PROJECT_ROOT/.env"
  fi
}

_info "Accessing working directory"
cd "$PROJECT_ROOT/" || _fail

_info "Cleaning up CI/CD variables"
delete_var "DOMAIN"
delete_var "DEPLOY_SERVER_DSN"
delete_var "DEPLOY_SERVER_ROOT"
delete_var "SSH_KEY_CONTENT"
delete_var "$DOTENV_CONTENT"
delete_var "AWS_ACCESS_KEY_ID"
delete_var "AWS_SECRET_ACCESS_KEY"
delete_var "AWS_DEFAULT_REGION"

_info "Preparing deploy environment"
if [ -z "$SSH_KEY" ]; then
  SSH_KEY="$HOME/.ssh/id_rsa"
fi

if [ -z "$DEPLOY_SERVER_ROOT" ]; then
  DEPLOY_SERVER_ROOT="/root/frontend"
fi

echo "{VAR} DOMAIN=$DOMAIN"
echo "{VAR} DEPLOY_SERVER_DSN=$DEPLOY_SERVER_DSN"
echo "{VAR} DEPLOY_SERVER_ROOT=$DEPLOY_SERVER_ROOT"
echo "{VAR} SSH_KEY=$SSH_KEY"

_info "Creating a deployment ssh key"
tmp_ssh_key_file=$(mktemp)
ssh-keygen -q -t rsa -N '' -f "$tmp_ssh_key_file" <<<y 2>&1 >/dev/null || _fail
public_ssh_key=$(cat "$tmp_ssh_key_file.pub")

_info "Whitelisting deployment key on remote server"
_CMD="$(cat <<-EOF
function _info() {
  echo ""
  echo " ===> \$1"
  echo ""
}

function _fail() {
  if [ ! -z "\$1" ]; then
    echo "\$1" 1>&2
  fi
  exit 1
}

_info 'Adding authorized ssh key: $public_ssh_key'
echo '$public_ssh_key' >> $AUTHORIZED_KEYS_FILE || _fail
EOF
)"
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" -t "$DEPLOY_SERVER_DSN" "$_CMD" || _fail

_info "Persisting CI/CD variables"
create_var "SSH_KEY_CONTENT" "$(cat $tmp_ssh_key_file)" || _fail
create_var "DEPLOY_SERVER_DSN" "$DEPLOY_SERVER_DSN" || _fail
create_var "DEPLOY_SERVER_ROOT" "$DEPLOY_SERVER_ROOT" || _fail
create_var "DOMAIN" "$DOMAIN" || _fail
create_var "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID" || _fail
create_var "AWS_SECRET_ACCESS_KEY" "$AWS_ACCESS_KEY_ID" || _fail
create_var "AWS_REGION" "$AWS_REGION" || _fail
create_var_file "$DOTENV_CONTENT" "$(cat $(_env_file "$ENVIRONMENT"))" || _fail
if [ -z "$AWS_DEFAULT_REGION" ]; then
  create_var "AWS_DEFAULT_REGION" "$AWS_REGION" || _fail
else
  create_var "AWS_DEFAULT_REGION" "$AWS_DEFAULT_REGION" || _fail
fi

_info "Cleaning up artifacts"
rm "$tmp_ssh_key_file" "$tmp_ssh_key_file.pub" || _fail