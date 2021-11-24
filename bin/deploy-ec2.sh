#!/usr/bin/env bash

# These values are mainly docker-composer.yml mirror
FORCE_RENEW='false'
DOCKER_COMPOSE_FILE="docker-compose-ec2.yml"
FRONTEND_SERVICE_NAME="frontend"
UFW_REQUIREMENTS_SCRIPT="/usr/share/ufw/check-requirements"

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

source "$SCRIPT_DIR/_helpers.sh"

if [ -f .env ]; then
  source .env
  _info "ENVIRONMENT=$ENVIRONMENT"
  if [ -z $ENVIRONMENT ]; then _fail '{ENVIRONMENT=$ENVIRONMENT} - environment variable is null, not found into .env'; fi
elif [[ "$1" == "dev"* || "$1" == "staging" ]]; then
  _info "ENVIRONMENT=$1"
  ENVIRONMENT=$1
  source .env.$ENVIRONMENT
else
  _fail 'environment does not specified, file .env / .env.dev / example ./bin/deploy-ec2.sh  dev'
  exit 100
fi

_info "Validate environment"
if [ -z "$DEPLOY_SERVER_DSN" ]; then
  _fail "Missing deploy server configuration (DEPLOY_SERVER_DSN)"
elif [ -z "$(which rsync)" ]; then
  _fail "Missing rsync utility"
elif [ -z "$DOMAIN" ]; then
  _fail "Missing domain required for setting up SSL certificate (DOMAIN)"
fi

if [ -z "$DEPLOY_SERVER_DSN" ]; then
  _fail "Missing deploy server configuration (DEPLOY_SERVER_DSN)"
elif [ -z "$(which rsync)" ]; then
  _fail "Missing rsync utility"
elif [ "$USE_HTTPS" == 1 ] && [ -z "$DOMAIN" ]; then
  _fail "Missing domain required for setting up SSL certificate (DOMAIN)"
fi

_info "Configure environment"
WEBSITE_URL="https://$DOMAIN"

if [ "$RENEW_CERTIFICATE" == 1 ]; then
  FORCE_RENEW='true'
fi

if [ -z "$SSH_KEY" ]; then
  SSH_KEY="$HOME/.ssh/id_rsa"
fi

if [ -z "$DEPLOY_SERVER_ROOT" ]; then
  DEPLOY_SERVER_ROOT="/root/frontend"
fi

DEPLOY_SERVER_PROJECT_PATH="$DEPLOY_SERVER_ROOT/project/$FRONTEND_SERVICE_NAME"

echo "{ENV} DOMAIN=$DOMAIN"
echo "{ENV} FORCE_RENEW=$FORCE_RENEW"

echo "{VAR} DEPLOY_SERVER_DSN=$DEPLOY_SERVER_DSN"
echo "{VAR} DEPLOY_SERVER_ROOT=$DEPLOY_SERVER_ROOT"
echo "{VAR} WEBSITE_URL=$WEBSITE_URL"
echo "{VAR} SSH_KEY=$SSH_KEY"

_info "Accessing working directory"
cd "$PROJECT_ROOT/" || _fail

_info "Sending files to remote server"
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" -t "$DEPLOY_SERVER_DSN" "mkdir -pv $DEPLOY_SERVER_PROJECT_PATH" || _fail

_info "Sending files to remote server"
rsync -av -delete --cvs-exclude \
  --exclude src/ --exclude public/ --exclude bin/ --exclude *test*/  --exclude .env*/ --exclude ./.idea/  \
  --include $DOCKER_COMPOSE_FILE --include ./.env --include ./.env.$ENVIRONMENT  \
  -e "ssh -o StrictHostKeyChecking=no -i '$SSH_KEY'" ./ "$DEPLOY_SERVER_DSN:$DEPLOY_SERVER_PROJECT_PATH/" || _fail "Failed to send files to remote server"

_CMD="$(cat <<-EOF
echo -e '\n ===>  Clean unused docker all objects'
docker system prune --all -f
echo -e  '\n ===> Clean unused docker volumes objects (all dangling build cache)'
docker system prune --volumes -f
echo -e  '\n ===>  AWS Configure'
mkdir -pv ~/.aws
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
aws configure set region ${AWS_REGION}
cd $DEPLOY_SERVER_PROJECT_PATH
echo -e  "\n ===> aws ecr get-login-password --region $AWS_REGION | docker login -u AWS --password-stdin  $repository_url"
aws ecr get-login-password --region $AWS_REGION | docker login -u AWS --password-stdin  $repository_url
if [[ -f .env.$ENVIRONMENT && ! -f .env ]]; then mv -v .env.$ENVIRONMENT .env; else ls -la .env.$ENVIRONMENT; fi
if [[ ! -z $VERSION_TAG ]]; then echo >> .env; echo "VERSION_TAG=$VERSION_TAG" >> .env; fi
echo -e  '\n ===> Run docker-compose -f 'docker-compose-ec2.yml'  build --no-cache'
docker-compose -f 'docker-compose-ec2.yml' up -d
EOF
)"

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" -t "$DEPLOY_SERVER_DSN" "$_CMD" || _fail
