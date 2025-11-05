#!/usr/bin/env bash
set -xeu

debug(){
  echo "[DEBUG] $*"
}

warn(){
  echo "[WARN] $*"
}

error(){
  echo "[ERROR] $*"
  exit 1
}

set-default() {
  local key="$1"
  local value="$2"
  if [ -z "${!key:-}" ]; then
    debug "$key is not set defaulting to $value"
    declare -g "$key=$value"
    export "${key?}"
  fi
}

warn-empty() {
  local key="$1"
  shift
  local message="$*"
  if [ -z "${!key:-}" ]; then
    warn "$key is not set, $message"
  fi
}

if [ -z "${1:-}" ]; then
  exec "$@"
fi

if [ -f "${DB_PASS_FILE:-/}" ];then
  DB_PASS="$(cat "${DB_PASS_FILE}" | tr -d '\n ')"
  export DB_PASS
fi


(
  echo "${BACKUP_CRON:?"BACKUP_CRON env var must be set"}" >>dev/null
  echo "${DB_HOST:?"DB_HOST env var must be set"}" >>dev/null
  echo "${DB_USER:?"DB_USER env var must be set"}" >>dev/null
  warn-empty DB_PASS "DB_PASS env var is empty, ignorable"
  warn-empty DB_NAME "DB_NAME env var is empty, triggering a full-backup"
  #TODO: TLS config verification
  warn-empty CRON_ON_SUCCESS "CRON_ON_SUCCESS env var is empty, ignorable"
  warn-empty CRON_ON_FAIL "CRON_ON_FAIL env var is empty, ignorable"
)

set-default BACKUP_ON_INIT 0
set-default BACKUP_RETRY 0
set-default BACKUP_TIMEOUT 1h
set-default BACKUP_DIRECTORY /backups
set-default BACKUP_THREADS 8
set-default BACKUP_NAME '{{ now | date "2006-01-02_15-04-05" }}'
set-default CRON_CONFIG_FILE "/tmp/cron.yaml"

if [ ! -d "$BACKUP_DIRECTORY" ];then
  if [ -f "$BACKUP_DIRECTORY" ];then
    error "Backup directory is set to ${BACKUP_DIRECTORY} but its a file"
  fi
  mkdir -p "${BACKUP_DIRECTORY}"
fi

for i in $(find /init.d/*.sh | sort); do
  trap 'echo "an error happened in file $i"' ERR
  debug "Sourcing $i"
  source "$i"
done
gomplate -f /crontab.yaml.tmpl -o "${CRON_CONFIG_FILE}"
crontab-go -c "${CRON_CONFIG_FILE}"