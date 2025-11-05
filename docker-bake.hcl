variable "opts" {
  default = {
    base_image_name= "ghcr.io/fmotalleb/db-sidecar"
    crontab_version = "latest-slim"
    gomplate_version="v4.3.3"
  }
}

group "default" {
  targets = [
    "pg-utils",
    "mysql-utils",
    "base"
  ]
}

# Base template
target "_base" {
  context = "."
  pull = true
  push = true
  provenance = false
  args = {
    CRONTAB_TAG = "${opts.crontab_version}"
    GOMPLATE_VERSION = "${opts.gomplate_version}"
  }
}

target "base" {
  inherits = ["_base"]
  tags = [
    "${opts.base_image_name}:base",
    "${opts.base_image_name}:latest",
  ]
  target = "base"
}

target "pg-utils" {
  inherits = ["_base"]
  tags = [
    "${opts.base_image_name}:pg-utils",
    "${opts.base_image_name}:pg",
    "${opts.base_image_name}:postgres",
  ]
  target = "pg-utils"
}

target "mysql-utils" {
  inherits = ["_base"]
  tags = [
    "${opts.base_image_name}:mysql-utils",
    "${opts.base_image_name}:mariadb-utils",
    "${opts.base_image_name}:mysql",
    "${opts.base_image_name}:mariadb",
  ]
  target = "mysql-utils"
}
