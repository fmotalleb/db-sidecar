ARG CRONTAB_TAG="latest-slim"
FROM ghcr.io/fmotalleb/crontab-go:${CRONTAB_TAG} AS base

SHELL [ "bash" , "-c" ]

# this changes the shell for crontab itself
ENV SHELL="bash"

ARG GOMPLATE_VERSION="v4.3.3"
ENV GOMPLATE_VERSION="${GOMPLATE_VERSION}"
RUN --mount=type=tmpfs,target=/var/lib/apt/lists/ \
  --mount=type=tmpfs,target=/var/cache/apt/archives/ \
  --mount=type=tmpfs,target=/install\
  <<EOF 
set -eu -o pipefail
apt-get update
apt-get full-upgrade -y
apt-get install -y curl zip unzip zstd rsync pv yq
cd /install
zipname="rclone-current-linux-amd64.zip"
curl -LO "https://downloads.rclone.org/$zipname"
unzip "$zipname"
mv ./rclone-*/rclone /usr/local/bin
GOMPLATE_URL="https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64"
curl -L "${GOMPLATE_URL}" -o /usr/local/bin/gomplate
chmod +x /usr/local/bin/gomplate
EOF

FROM base AS pg-utils

RUN --mount=type=tmpfs,target=/var/lib/apt/lists/ \
  --mount=type=tmpfs,target=/var/cache/apt/archives/ \
  <<EOF 
set -eu -o pipefail
apt-get update
apt-get install -y postgresql-client
EOF

FROM base AS mysql-utils

RUN --mount=type=tmpfs,target=/var/lib/apt/lists/ \
  --mount=type=tmpfs,target=/var/cache/apt/archives/ \
  <<EOF 
set -eu -o pipefail
curl -L 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1D357EA7D10C9320371BDD0279EA15C0E82E34BA&exact=on' \
  -o /etc/apt/keyrings/mydumper.asc
source /etc/os-release
echo "deb [signed-by=/etc/apt/keyrings/mydumper.asc] https://mydumper.github.io/mydumper/repo/apt/debian $VERSION_CODENAME main" >/etc/apt/sources.list.d/mydumper.list
apt-get update
apt-get install -y mydumper mariadb-client
EOF