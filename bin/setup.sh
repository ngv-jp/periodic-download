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
  OPTS=`getopt -o c: -l converter: -- "$@"`
  if [ $? -ne 0 ]; then
    return 1
  fi
  eval set -- "$OPTS"
  while true; do
    case "$1" in
      '-c' | '--converter')
        HTTP_HEADER_CONV="$2"
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
  if [ -z "$HTTP_HEADER_CONV" ]; then
    TEMP="$REQUIRE_OPTS --converter"
    REQUIRE_OPTS="$TEMP"
  fi
  if [ -n "$REQUIRE_OPTS" ]; then
    log_error "Require option(s):\n $REQUIRE_OPTS"
    return 1
  fi
  return 0
}

init_submodule() {
  (cd ..; git submodule update --init)
  if [ $? -ne 0 ]; then
    return 1
  fi
  return 0
}

build_converter() {
  (cd ../converter; go build conv/main/header.go)
  if [ $? -ne 0 ]; then
    return 1
  fi
  return 0
}

make_converter_link() {
  ln -s ../converter/header "$1"
  if [ $? -ne 0 ]; then
    return 1
  fi
  return 0
}

load_params "$@"
if  [ $? -ne 0 ]; then
  USAGE=`cat << EOT
Usage:
  $SHELL_PATH <--converter Converter>
Options:
  converter HTTP Response Header Converter
EOT`
  log_error "$USAGE"
  exit 1
fi
if [ -e "$HTTP_HEADER_CONV" ]; then
  exit 0
fi

init_submodule
if [ $? -ne 0 ]; then
  log_error "Git submodule initialize failed."
  exit 1
fi

build_converter
if [ $? -ne 0 ]; then
  log_error "Converter build failed."
  exit 1
fi

make_converter_link "$HTTP_HEADER_CONV"
if [ $? -ne 0 ]; then
  log_error "Unable to create link."
  exit 1
fi
exit 0
