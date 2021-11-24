#!/usr/bin/env bash

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
DOCKER_COMPOSE_FILE="docker-compose.yml"

source "$SCRIPT_DIR/_helpers.sh"

if [ -z "$DEPLOY_SERVER_DSN" ]; then
  _fail "Missing deploy server configuration (DEPLOY_SERVER_DSN)"
elif [ -z "$1" ]; then
  _fail "Missing docker service argument (\$1)"
fi

SERVICE="$1"

if [ -z "$SSH_KEY" ]; then
  SSH_KEY="$HOME/.ssh/id_rsa"
fi

if [ -z "$DEPLOY_SERVER_ROOT" ]; then
  DEPLOY_SERVER_ROOT="/root/frontend"
fi

_info "Configure environment"
echo "{VAR} DEPLOY_SERVER_DSN=$DEPLOY_SERVER_DSN"
echo "{VAR} DEPLOY_SERVER_ROOT=$DEPLOY_SERVER_ROOT"
echo "{VAR} SERVICE=$SERVICE"
echo "{VAR} SSH_KEY=$SSH_KEY"

_info "Running command on remote server..."
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

if [ -z \$(which docker-compose) ]; then
  _fail 'Docker Compose not installed'
fi

cd '$DEPLOY_SERVER_ROOT' || _fail 'Failed to access working dir'
docker-compose -f '$DOCKER_COMPOSE_FILE' logs -f $SERVICE
EOF
)"
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" -t "$DEPLOY_SERVER_DSN" "$_CMD" || _fail
