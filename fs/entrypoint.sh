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
set-default BACKUP_REMOTE_BASEPATH "${BACKUP_DIRECTORY}"
set-default BACKUP_REMOTE_DIR "${BACKUP_REMOTE_BASEPATH}/${BACKUP_NAME}"
set-default CRON_CONFIG_FILE "/tmp/cron.yaml"
set-default RCLONE_TRANSFER_THREADS 8
set-default RCLONE_CHECKER_THREADS 8
set-default RCLONE_MULTI_THREAD_STREAMS 4

RCLONE_OPTS=" --transfers=${RCLONE_TRANSFER_THREADS} --checkers=${RCLONE_CHECKER_THREADS} --multi-thread-streams=${RCLONE_MULTI_THREAD_STREAMS}"

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


if [ -n "${S3_ENDPOINT}" ]; then
  S3_PROVIDER="${S3_PROVIDER:-Minio}"
  S3_ACCESS_KEY="${S3_ACCESS_KEY:-access}"
  S3_SECRET_KEY="${S3_SECRET_KEY:-secret}"
  S3_ACL="${S3_ACL:-private}"
  S3_REGION_OPT="${S3_REGION:+region=${S3_REGION}}"
  rclone config create storage s3 \
      provider="${S3_PROVIDER}" \
      access_key_id="${S3_ACCESS_KEY}" \
      secret_access_key="${S3_SECRET_KEY}" \
      endpoint="${S3_ENDPOINT}" \
      acl="${S3_ACL}" \
      ${S3_REGION_OPT}

  UPLOAD_COMMAND="rclone sync './${BACKUP_NAME}' storage:${BACKUP_REMOTE_DIR}${RCLONE_OPTS}"
  export UPLOAD_COMMAND
elif [ -n "${SFTP_SERVER}" ]; then
  # Required
  SFTP_HOST="${SFTP_HOST:-${SFTP_SERVER}}"
  SFTP_USER="${SFTP_USER:-root}"

  # Optional
  OPT_KEY_FILE=""
  OPT_PORT=""
  OPT_KNOWN_HOSTS=""
  OPT_KEY_PASSPHRASE=""

  [ -n "${SFTP_KEY_FILE}" ]       && OPT_KEY_FILE="key_file=${SFTP_KEY_FILE}"
  [ -n "${SFTP_PORT}" ]           && OPT_PORT="port=${SFTP_PORT}"
  [ -n "${SFTP_KNOWN_HOSTS}" ]    && OPT_KNOWN_HOSTS="known_hosts_file=${SFTP_KNOWN_HOSTS}"
  [ -n "${SFTP_KEY_PASSPHRASE}" ] && OPT_KEY_PASSPHRASE="key_file_pass=${SFTP_KEY_PASSPHRASE}"

  rclone config create storage sftp \
      host="${SFTP_HOST}" \
      user="${SFTP_USER}" \
      ${OPT_KEY_FILE} \
      ${OPT_PORT} \
      ${OPT_KNOWN_HOSTS} \
      ${OPT_KEY_PASSPHRASE}
    
  UPLOAD_COMMAND="rclone sync './${BACKUP_NAME}' storage:${BACKUP_REMOTE_DIR}${RCLONE_OPTS}"
  export UPLOAD_COMMAND
fi


gomplate -f /crontab.yaml.tmpl -o "${CRON_CONFIG_FILE}"


crontab-go -c "${CRON_CONFIG_FILE}"