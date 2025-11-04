# db-sidecar

A collection of Docker images designed to run as sidecars to your database containers. These images provide a set of utilities to help with database administration, such as backups, restores, and scheduled tasks.

## Features

- **Scheduled Jobs:** Based on `ghcr.io/fmotalleb/crontab-go`, allowing you to schedule tasks using a simple `crontab` file.
- **Backup & Sync:** Includes `rclone` for backing up and syncing data to and from various cloud storage providers.
- **Database Utilities:** Comes in two flavors, with tools for either PostgreSQL or MySQL/MariaDB.
- **Compression & Archiving:** Includes `zip`, `unzip`, and `zstd` for file compression and archiving.
- **Efficient Data Transfer:** Includes `rsync` and `pv` for efficient and observable data transfers.

## Available Tags

The following tags are available on `ghcr.io/fmotalleb/db-sidecar`:

### PostgreSQL

- `ghcr.io/fmotalleb/db-sidecar:pg-utils`
- `ghcr.io/fmotalleb/db-sidecar:pg`
- `ghcr.io/fmotalleb/db-sidecar:postgres`

These images include the `postgresql-client`.

### MySQL/MariaDB

- `ghcr.io/fmotalleb/db-sidecar:mysql-utils`
- `ghcr.io/fmotalleb/db-sidecar:mariadb-utils`
- `ghcr.io/fmotalleb/db-sidecar:mysql`
- `ghcr.io/fmotalleb/db-sidecar:mariadb`

These images include `mydumper` and `mariadb-client`.

## Usage

### Basic Usage

You can run the sidecar container alongside your database container. For example, using `docker-compose`:

```yaml
services:
  db:
    image: postgres:16
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=testdb
  db-sidecar:
    image: ghcr.io/fmotalleb/db-sidecar:pg
    environment:
      - PGPASSWORD=password
    volumes:
      - ./backups:/backups
      - ./crontab:/etc/crontab
      - ./rclone.conf:/.rclone.conf
```

### Backups with rclone

You can use `rclone` to back up your database to a cloud storage provider.

1.  **Configure rclone:** Create an `rclone.conf` file with your storage provider's configuration.

2.  **Create a backup script:**

    ```bash
    #!/bin/bash
    set -eu -o pipefail

    DB_USER="user"
    DB_HOST="db"
    DB_NAME="testdb"
    BACKUP_DIR="/backups"
    REMOTE_NAME="my-s3-remote"
    BUCKET_NAME="my-backup-bucket"

    mkdir -p "$BACKUP_DIR"
    
    # Dump the database
    pg_dump -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" | gzip > "$BACKUP_DIR/backup.sql.gz"

    # Upload to cloud storage
    rclone copy "$BACKUP_DIR/backup.sql.gz" "$REMOTE_NAME:$BUCKET_NAME"
    ```

3.  **Schedule the backup:** Use a `crontab` file to schedule the backup script to run at regular intervals.

    ```
    # /etc/crontab
    0 1 * * * /path/to/your/backup-script.sh
    ```

## Building

To build the images locally, you need to have Docker with `buildx` installed.

```sh
docker buildx bake
```

You can also build a specific target:

```sh
docker buildx bake pg-utils
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
