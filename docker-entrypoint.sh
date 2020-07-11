#!/bin/bash
# Entrypoint for Docker Container

set -e

default_filter="(|(username={{username}})(mail={{username}}))"

PORT_TRUSTED=${PORT_TRUSTED:-'3000'}
PORT_SANDBOX=${PORT_SANDBOX:-'3003'}
PORT_PUBLIC=${PORT_PUBLIC:-'3004'}
URL_BASE_TRUSTED=${URL_BASE_TRUSTED:-"http://localhost:${PORT_TRUSTED}"}
URL_BASE_SANDBOX=${URL_BASE_SANDBOX:-"http://localhost:${PORT_SANDBOX}"}
URL_BASE_PUBLIC=${URL_BASE_PUBLIC:-"http://localhost:${PORT_PUBLIC}"}
WWW_HOST=${WWW_HOST:-'0.0.0.0'}
WWW_PROXY=${WWW_PROXY:-'false'}
WWW_SECRET=${WWW_SECRET:-$(pwgen -1)}
WITH_LDAP=${WITH_LDAP:-'false'}
LDAP_HOST=${LDAP_HOST:-'ldap'}
LDAP_PORT=${LDAP_PORT:-'389'}
LDAP_SECURE=${LDAP_SECURE:-'false'}
LDAP_BIND_USER=${LDAP_BIND_USER:-'name@company.net'}
LDAP_BIND_PASS=${LDAP_BIND_PASS:-'mySecretPassword'}
LDAP_FILTER=${LDAP_FILTER:-${default_filter}}
LDAP_BASEDN=${LDAP_BASEDN:-ou=users,dc=company}
LDAP_UIDTAG=${LDAP_UIDTAG:-'username'}
LDAP_MAILTAG=${LDAP_MAILTAG:-'mail'}
LDAP_NAMETAG=${LDAP_NAMETAG:-'username'}
LDAP_METHOD=${LDAP_METHOD:-'ldapjs'}
MONGO_HOST=${MONGO_HOST:-'mongo'}
WITH_REDIS=${WITH_REDIS:-'true'}
REDIS_HOST=${REDIS_HOST:-'redis'}
MYSQL_HOST=${MYSQL_HOST:-'mysql'}
MYSQL_DATABASE=${MYSQL_DATABASE:-'mailtrain'}
MYSQL_USER=${MYSQL_USER:-'mailtrain'}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-'mailtrain'}
WITH_ZONE_MTA=${WITH_ZONE_MTA:-'true'}
POOL_NAME=${POOL_NAME:-$(hostname)}

SENDER_PROCESSES=${SENDER_PROCESSES:-'5'}
LOG_LEVEL=${LOG_LEVEL:-'info'}
MAX_POST_SIZE=${MAX_POST_SIZE:-'2MB'}
WITH_REPORTS=${WITH_REPORTS:-'true'}

RETENTION_CAMPAIGN=${RETENTION_CAMPAIGN:-'86400'}
RETENTION_TRIGGERED=${RETENTION_TRIGGERED:-'86400'}
RETENTION_TEST=${RETENTION_TEST:-'300'}
RETENTION_SUBSCRIPTION=${RETENTION_SUBSCRIPTION:-'300'}
RETENTION_API=${RETENTION_API:-'3600'}

GDPR_DELETE_DATA=${GDPR_DELETE_DATA:-'true'}
GDPR_DELETE_SUBSCRIPTION=${GDPR_DELETE_SUBSCRIPTION:-'true'}
GDPR_DATA_RETENTION=${GDPR_DATA_RETENTION:-'86400'}
GDPR_SUBSCRIPTION_RETENTION=${GDPR_SUBSCRIPTION_RETENTION:-'2592000'}

# Warning for users that already rely on the MAILTRAIN_SETTING variable
# Can probably be removed in the future.
MAILTRAIN_SETTING=${MAILTRAIN_SETTINGS:-}
if [ ! -z "$MAILTRAIN_SETTING" ]; then
    echo 'Error: MAILTRAIN_SETTINGS is no longer supported. See README.md'
    exit 1
fi

if [ -f server/config/production.yaml ]; then
    echo 'Info: application/production.yaml already provisioned'
else
    echo 'Info: Generating application/production.yaml'

    # Basic configuration
    cat >> server/config/production.yaml <<EOT
gdpr:
  deleteDataAfterUnsubscribe:
    enabled: $GDPR_DELETE_DATA
    secondsAfterUnsubscribe: $GDPR_DATA_RETENTION

  deleteSubscriptionAfterUnsubscribe:
    enabled: $$GDPR_DELETE_SUBSCRIPTION
    secondsAfterUnsubscribe: $GDPR_SUBSCRIPTION_RETENTION

www:
  host: $WWW_HOST
  proxy: $WWW_PROXY
  secret: $WWW_SECRET
  trustedPort: $PORT_TRUSTED
  sandboxPort: $PORT_SANDBOX
  publicPort: $PORT_PUBLIC
  trustedUrlBase: $URL_BASE_TRUSTED
  sandboxUrlBase: $URL_BASE_SANDBOX
  publicUrlBase: $URL_BASE_PUBLIC
  maxPostSize: $MAX_POST_SIZE

mysql:
  host: $MYSQL_HOST
  database: $MYSQL_DATABASE
  user: $MYSQL_USER
  password: $MYSQL_PASSWORD

editors:
- mosaico
- mosaicoWithFsTemplate

enabledLanguages:
- en-US

tagLanguages:
- simple

log:
  level: $LOG_LEVEL

reports:
  enabled: $WITH_REPORTS


redis:
  enabled: $WITH_REDIS
  host: $REDIS_HOST

builtinZoneMTA:
  enabled: $WITH_ZONE_MTA
  log:
    level: warn
  mongo: mongodb://${MONGO_HOST}:27017/zone-mta
  redis: redis://${REDIS_HOST}:6379/2
  poolName: $POOL_NAME

queue:
  processes: $SENDER_PROCESSES

  retention:
    # Regular and RSS campaign. Once this expires, the campaign is considered finished. The remaining recipients
    # are included in the set of those recipients to whom the message would be delivered if the campaign is again started.
    campaign: $RETENTION_CAMPAIGN
    # Triggered campaign. Once this expires, the message gets discarded.
    triggered: $RETENTION_TRIGGERED   # 1 day
    # Test send (in campaign or template)
    test: $RETENTION_TEST          # 5 minutes
    # Subscription and password reset related emails
    subscription: $RETENTION_SUBSCRIPTION  # 5 minutes
    # Transactional emails sent via API (i.e. /templates/:templateId/send)
    apiTransactional: $RETENTION_API  # 60 minutes
EOT

    # Manage LDAP if enabled
    if [ "$WITH_LDAP" = "true" ]; then
        echo 'Info: LDAP enabled'
    cat >> server/config/production.yaml <<EOT
ldap:
  enabled: true
  host: $LDAP_HOST
  port: $LDAP_PORT
  secure: $LDAP_SECURE
  bindUser: $LDAP_BIND_USER
  bindPassword: $LDAP_BIND_PASS
  filter: $LDAP_FILTER
  baseDN: $LDAP_BASEDN
  uidTag: $LDAP_UIDTAG
  mailTag: $LDAP_MAILTAG
  nameTag: $LDAP_NAMETAG
  method: $LDAP_METHOD
EOT
    else
        echo 'Info: LDAP not enabled'
    cat >> server/config/production.yaml <<EOT
ldap:
  enabled: false
EOT
    fi

fi

if [ -f server/services/workers/reports/config/production.yaml ]; then
    echo 'Info: server/production.yaml already provisioned'
else
    echo 'Info: Generating server/production.yaml'
    cat > server/services/workers/reports/config/production.yaml <<EOT
mysql:
  host: $MYSQL_HOST
log:
  level: warn
EOT
fi

# Wait for the other services to start
echo 'Info: Waiting for MySQL Server'
while ! nc -z $MYSQL_HOST 3306; do sleep 1; done

if [ "$WITH_REDIS" = "true" ]; then
  echo 'Info: Waiting for Redis Server'
  while ! nc -z $REDIS_HOST 6379; do sleep 1; done
fi

if [ "$WITH_ZONE_MTA" = "true" ]; then
  echo 'Info: Waiting for MongoDB Server'
  while ! nc -z $MONGO_HOST 27017; do sleep 1; done
fi

# Mount the EFS if the env var is set
if [ ! -z "$EFS_MOUNT" ]; then
  mount -t efs $EFS_MOUNT:/ /app/server
fi

cd server
NODE_ENV=production node index.js
