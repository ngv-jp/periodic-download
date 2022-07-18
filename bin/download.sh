#!/bin/sh
# Copyright (c) 2022 RFull Development
# This source code is managed under the MIT license. See LICENSE in the project root.
SHELL_PATH="$0"
SHELL_DIR=`dirname "$0"`
PATH=$PATH:$SHELL_DIR

cd "$SHELL_DIR"
. ./log.sh

load_params() {
  local OPTS REQUIRE_OPTS TEMP

  # Option analysis
  OPTS=`getopt -o u:c:l: -l url:,converter:,last-modified: -- "$@"`
  if [ $? -ne 0 ]; then
    return 1
  fi
  eval set -- "$OPTS"
  while true; do
    case "$1" in
      '-u' | '--url')
        DOWNLOAD_URL="$2"
        shift 2
        continue
        ;;
      '-c' | '--converter')
        HTTP_HEADER_CONV="$2"
        shift 2
        continue
        ;;
      '-l' | '--last-modified')
        LAST_MODIFIED_STORE="$2"
        shift 2
        continue
        ;;
      '--')
        shift
        break
        ;;
      *)
        return 1
    esac
  done

  # Option validation
  if [ -z "$DOWNLOAD_URL" ]; then
    TEMP="$REQUIRE_OPTS --url"
    REQUIRE_OPTS="$TEMP"
  fi
  if [ -z "$HTTP_HEADER_CONV" ]; then
    TEMP="$REQUIRE_OPTS --converter"
    REQUIRE_OPTS="$TEMP"
  elif [ ! -e "$HTTP_HEADER_CONV" ]; then
    log_error "'$HTTP_HEADER_CONV' is not exist."
    return 1
  fi
  if [ -z "$LAST_MODIFIED_STORE" ]; then
    TEMP="$REQUIRE_OPTS --last-modified"
    REQUIRE_OPTS="$TEMP"
  fi
  if [ -n "$REQUIRE_OPTS" ]; then
    log_error "Require options:\n $REQUIRE_OPTS"
    return 1
  fi
  return 0
}

check_update() {
  local HEADER RAW CODE

  # Request to Web
  if [ -n "$2" ]; then
    HEADER="If-Modified-Since: \"$2\""
    RAW=`curl "$1" --head --header "$HEADER"`
  else
    RAW=`curl "$1" --head`
  fi
  if [ $? -ne 0 ]; then
    log_error 'Invalid argument.'
    return 2
  fi

  # Analyze response from the web
  RESPONSE=`echo "$RAW" | $3`
  CODE=`echo "$RESPONSE" | jq -e -r ".code" | bc`
  if [ $? -ne 0 ]; then
    log_error "HTTP Status code is not in response."
    return 2
  elif [ $CODE -eq 304 ]; then
    log_error 'Content is not updated.'
    return 1
  elif [ $CODE -ne 200 ]; then
    log_error 'Can not download.'
    return 2
  fi
  return 0
}

download() {
  log_info "Start downloading from '$1'."
  wget "$1" | bc
  if [ $? -ne 0 ]; then
    log_error 'Can not download.'
    return 1
  fi
  log_info 'Download completed.'
  return 0
}

load_last_modified() {
  if [ ! -e "$1" ]; then
    LAST_MODIFIED=
    return 1
  fi

  log_info "Last Modified read from '$1'."
  LAST_MODIFIED=`cat $1 | tr -d "\r" | tr -d "\n"`
  if [ $? -ne 0 ]; then
    LAST_MODIFIED=
    return 1
  fi
  return 0
  log_info "Done."
}

save_last_modified() {
  local LAST_MODIFIED

  log_info "Last Modified write to '$2'."
  LAST_MODIFIED=`echo "$1" | jq -e -r ".lastModified"`
  if [ $? -ne 0 ]; then
    log_error 'Last modified is not in response.'
    return 1
  fi
  echo "$LAST_MODIFIED" > "$2"
  if [ $? -ne 0 ]; then
    log_error "Write failed."
    return 1
  fi
  log_info "Done."
  return 0
}

load_params "$@"
if  [ $? -ne 0 ]; then
  USAGE=`cat << EOT
Usage:
  $SHELL_PATH <--url URL> <--converter Converter> <-- --last-modified Path>
Options:
  url           Download URL
  converter     HTTP Response Header Converter
  last-modified Content last modified store path
EOT`
  log_error "$USAGE"
  exit 1
fi

load_last_modified "$LAST_MODIFIED_STORE"

check_update "$DOWNLOAD_URL" "$LAST_MODIFIED" "$HTTP_HEADER_CONV"
if  [ $? -eq 1 ]; then
  exit 0
elif [ $? -eq 0 ]; then
  exit 0
fi

download "$DOWNLOAD_URL"
if  [ $? -ne 0 ]; then
  exit 1
fi

save_last_modified "$RESPONSE" "$LAST_MODIFIED_STORE"
exit 0
