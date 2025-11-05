#!/usr/bin/env bash

cmd=(
  "mydumper" 
  "--host='$DB_HOST'"
  "--user='$DB_USER'"
  "--threads=$BACKUP_THREADS"
  "--outputdir=$BACKUP_NAME"
  '--clear'
  '--trx-tables=0'
)

if [ ! -z "${DB_PASS:-}" ];then 
  cmd+=("--password='${DB_PASS}'")
fi
if [ ! -z "${DB_NAME:-}" ];then 
  cmd+=("---database='${DB_NAME}'")
fi

BACKUP_COMMAND="${cmd[*]}"
export BACKUP_COMMAND