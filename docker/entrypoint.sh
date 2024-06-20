#!/bin/bash

if [ -d /usr/share/nginx/html/moodledata ]; then
  chown -R www-data:www-data /usr/share/nginx/html/moodledata
  chmod -R 0755 /usr/share/nginx/html/moodledata
fi

cd /usr/share/nginx/html/moodle

set -euo pipefail

file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

envs=(
  MOODLE_DB_TYPE
  MOODLE_DB_HOST
  MOODLE_DB_PORT
  MOODLE_DB_NAME
  MOODLE_DB_USER
  MOODLE_DB_PASSWORD
  MOODLE_DB_PREFIX
  MOODLE_WWW_ROOT
  MOODLE_DATA_ROOT
)
haveConfig=
for e in "${envs[@]}"; do
  file_env "$e"
  if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
    haveConfig=1
  fi
done

if [ "$haveConfig" ]; then
  : "${MOODLE_DB_TYPE:=mariadb}"
  : "${MOODLE_DB_HOST:=database}"
  : "${MOODLE_DB_PORT:=3306}"
  : "${MOODLE_DB_NAME:=moodle}"
  : "${MOODLE_DB_USER:=root}"
  : "${MOODLE_DB_PASSWORD:=}"
  : "${MOODLE_DB_PREFIX:=mdl_}"
  : "${MOODLE_WWW_ROOT:=http://localhost}"
  : "${MOODLE_DATA_ROOT:=/usr/share/nginx/html/moodledata}"

  if [ ! -e "config.php" ]; then
    mv config-dist.php config.php
    chown nginx config.php
  fi

  sed_escape_lhs() {
    echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
  }
  sed_escape_rhs() {
    echo "$@" | sed -e 's/[\/&]/\\&/g'
  }
  php_escape() {
    php -r 'var_export(('$2') $argv[1]);' -- "$1"
  }
  set_config() {
    key="$1"
    value="$2"
    var_type="${3:-string}"
    start="(\\\$CFG->)$(sed_escape_lhs "$key")\s*="
    end=";.*"
    if [ "$key" == "dbport" ]; then
      start="(['\"])$(sed_escape_lhs "$key")\2\s*=>"
      end=",.*"
    fi
    sed -ri -e "s/($start\s*).*($end)$/\1$(sed_escape_rhs "$(php_escape "$value" "$var_type")")\3/" config.php
  }

  set_config 'dbtype'   "$MOODLE_DB_TYPE"
  set_config 'dbhost'   "$MOODLE_DB_HOST"
  set_config 'dbport'   "$MOODLE_DB_PORT"
  set_config 'dbname'   "$MOODLE_DB_NAME"
  set_config 'dbuser'   "$MOODLE_DB_USER"
  set_config 'dbpass'   "$MOODLE_DB_PASSWORD"
  set_config 'prefix'   "$MOODLE_DB_PREFIX"
  set_config 'wwwroot'  "$MOODLE_WWW_ROOT"
  set_config 'dataroot' "$MOODLE_DATA_ROOT"

  for e in "${envs[@]}"; do
    unset "$e"
  done
fi

exec "$@"

cd /

/usr/bin/supervisord