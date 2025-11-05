# DB Sidecar

This project provides a sidecar container for backing up databases. It supports both MySQL and PostgreSQL.

## How it works

The sidecar container runs a cron job that periodically backs up the database. The backup command is generated based on the environment variables provided to the container.

## Configuration

The sidecar is configured using environment variables. The following variables are available:

### General

| Variable | Description | Default |
|---|---|---|
| `BACKUP_CRON` | Cron expression for scheduling backups. | **Required** |
| `DB_HOST` | Database host. | **Required** |
| `DB_USER` | Database user. | **Required** |
| `DB_PASS` | Database password. | |
| `DB_PASS_FILE` | File to read the database password from. | |
| `DB_NAME` | Database name. If not set, a full backup is triggered. | |
| `CRON_ON_SUCCESS` | Command to execute on successful cron job completion. | |
| `CRON_ON_FAIL` | Command to execute on failed cron job completion. | |
| `BACKUP_ON_INIT` | Whether to perform a backup on container initialization. | `0` |
| `BACKUP_RETRY` | Number of retries for a failed backup. | `0` |
| `BACKUP_TIMEOUT` | Timeout for a backup. | `1h` |
| `BACKUP_DIRECTORY` | Directory to store backups. | `/backups` |
| `BACKUP_THREADS` | Number of threads to use for backup. | `8` |
| `BACKUP_NAME` | Name of the backup file. | Current timestamp (`{{ now \| date "2006-01-02_15-04-05" }}`) |
| `CRON_CONFIG_FILE` | Path to the cron configuration file. | `/tmp/cron.yaml` |

### MySQL

The `mydumper` command is used for MySQL backups.

### PostgreSQL

The `pg_dumpall` or `pg_dump` command is used for PostgreSQL backups. If `DB_NAME` is not set, `pg_dumpall` is used. Otherwise, `pg_dump` is used.

Note that only pg_dump supports multi threaded dump and restore, always try to provide a db name

## Usage

Images are published using Docker Bake and are available on the GitHub Container Registry (GHCR). You can retrieve them from there using:

- ghcr.io/fmotalleb/db-sidecar:postgres
- ghcr.io/fmotalleb/db-sidecar:mariadb

To use the sidecar, please checkout the example docker-compose.yaml in the repository.
