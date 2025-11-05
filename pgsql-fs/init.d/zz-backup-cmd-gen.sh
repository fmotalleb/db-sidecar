#!/usr/bin/env bash

cmd=()
if [ ! -z "${DB_PASS:-}" ];then 
  cmd+=('PGPASSWORD="${DB_PASS}"')
fi



if [ -z "${DB_NAME:-}" ];then
  cmd+=("pg_dumpall")
else 
  cmd+=("pg_dump"  "--format=directory" "--jobs=$BACKUP_THREADS")
fi

cmd+=(
  "--host='${DB_HOST}'"
  "--username='${DB_USER}'"
  "--file='${BACKUP_NAME}'"
  "--no-password"
)

if [ ! -z "${DB_NAME:-}" ];then 
  cmd+=("--dbname='${DB_NAME}'")
fi

BACKUP_COMMAND="${cmd[*]}"
export BACKUP_COMMAND
