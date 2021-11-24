#!/usr/bin/env bash

# These values are mainly docker-composer.yml mirror
FORCE_RENEW='false'
DOCKER_COMPOSE_FILE="docker-compose.yml"
FRONTEND_SERVICE_NAME="frontend"
UFW_REQUIREMENTS_SCRIPT="/usr/share/ufw/check-requirements"

SCRIPT_DIR=$(cd `dirname "$0"` && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

source "$SCRIPT_DIR/_helpers.sh"

_info "Validate environment"
if [ -z "$DEPLOY_SERVER_DSN" ]; then
  _fail "Missing deploy server configuration (DEPLOY_SERVER_DSN)"
elif [ -z "$(which rsync)" ]; then
  _fail "Missing rsync utility"
elif [ -z "$DOMAIN" ]; then
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

echo "{ENV} DOMAIN=$DOMAIN"
echo "{ENV} FORCE_RENEW=$FORCE_RENEW"

echo "{VAR} DEPLOY_SERVER_DSN=$DEPLOY_SERVER_DSN"
echo "{VAR} DEPLOY_SERVER_ROOT=$DEPLOY_SERVER_ROOT"
echo "{VAR} WEBSITE_URL=$WEBSITE_URL"
echo "{VAR} SSH_KEY=$SSH_KEY"

_info "Accessing working directory"
cd "$PROJECT_ROOT/" || _fail

_info "Sending files to remote server"
rsync -av \
  --exclude node_modules/ --exclude build/ --exclude .vscode/ --exclude .git/ \
    -e "ssh -o StrictHostKeyChecking=no -i '$SSH_KEY'" ./ "$DEPLOY_SERVER_DSN:$DEPLOY_SERVER_ROOT/" || _fail "Failed to send files to remote server"

_info "Deploying on remote server..."
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

if [ ! -d '$DEPLOY_SERVER_ROOT' ]; then
  _info 'Creating working directory'
  mkdir -p '$DEPLOY_SERVER_ROOT' || _fail 'Failed to create working dir'
fi

cd '$DEPLOY_SERVER_ROOT' || _fail 'Failed to access working dir'

if [ -z \$(which ufw) ] || [ -z \$(which docker) ]; then
  _info 'Update softwaare repositories'
  apt-get update || _fail 'Failed to prepare software repository'
fi

if [ -z \$(which ufw) ] || [ "\$(ufw status || echo 'Status: inactive')" == 'Status: inactive' ]; then
  _info 'Setting up ufw (firewall)'

  if [ -z \$(which ufw) ]; then  
    apt install -y ufw || _fail 'Failed to install ufw'
  fi

  if [ -f '$UFW_REQUIREMENTS_SCRIPT' ]; then
    '$UFW_REQUIREMENTS_SCRIPT' -f || _fail 'Failed to check ufw installation'
  else
    _info 'Missing ufw requirements script: $UFW_REQUIREMENTS_SCRIPT. Skipping...'
  fi
  
  ufw allow ssh && ufw allow http && ufw allow https || _fail 'Unable to add ufw rules'
  ufw --force enable || _fail 'Failed to enable ufw'
fi

if [ -z \$(which docker) ]; then
  _info 'Setting up Docker'
  apt install -y docker.io || _fail 'Failed to install Docker'
  systemctl start docker || _fail 'Failed to start Docker service'
  systemctl enable docker || _fail 'Failed to enable Docker service'
fi

if [ -z \$(which docker-compose) ]; then
  _info 'Setting up Docker Compose'
  curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose || _fail 'Failed to install Docker Compose'
  chmod +x /usr/local/bin/docker-compose || _fail 'Failed to setup Docker Compose binary permissions'
fi

if [ -z \$(which npm) ]; then
  if [ ! -f '/root/.nvm/nvm.sh' ]; then
    _info 'Setting up NVM'
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash || _fail 'Failed to install NVM'
    . /root/.nvm/nvm.sh || _fail 'Failed to load NVM'
    nvm i 12 || _fail 'Failed to install Node.js'
  else
    _info 'Loading NVM'
    . /root/.nvm/nvm.sh || _fail 'Failed to load NVM'
  fi
fi

_info 'Validating environment'
docker --version || _fail 'Missing Docker binary'
docker-compose --version || _fail 'Missing Docker Compose binary'
echo 'Node version '\$(node -v) || _fail 'Missing Node.js binary'
echo 'Npm version '\$(npm -v) || _fail 'Missing Npm binary'

_info 'Clean unused docker all objects'
docker system prune --all -f
_info 'Clean unused docker volumes objects (all dangling build cache)'
docker system prune --volumes -f

_info 'Build $FRONTEND_SERVICE_NAME docker-compose service image'
WEBSITE_URL_ARG='WEBSITE_URL=$WEBSITE_URL'
echo '{ARG} '\$WEBSITE_URL_ARG
docker-compose build  --no-cache  --build-arg "\$WEBSITE_URL_ARG" \
    $FRONTEND_SERVICE_NAME || _fail 'Unable to build $FRONTEND_SERVICE_NAME docker-compose service image'

_info 'Bootstrapping services from $DOCKER_COMPOSE_FILE'
DOMAIN='$DOMAIN' FORCE_RENEW='$FORCE_RENEW' docker-compose -f '$DOCKER_COMPOSE_FILE' up -d --no-build

_info 'Listing running docker services'
docker-compose -f '$DOCKER_COMPOSE_FILE' ps || _fail 'Failed to list Docker services'
EOF
)"
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" -t "$DEPLOY_SERVER_DSN" "$_CMD" || _fail
