#!/bin/sh
# Copyright (c) 2022 RFull Development
# This source code is managed under the MIT license. See LICENSE in the project root.
load_params() {
  local OPTS REQUIRE_OPTS TEMP

  # オプションを解析
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

  # オプション確認
  if [ -z $HTTP_HEADER_CONV ]; then
    TEMP="$REQUIRE_OPTS --converter"
    REQUIRE_OPTS="$TEMP"
  fi
  if [ -n "$REQUIRE_OPTS" ]; then
    echo "Require options:\n $REQUIRE_OPTS"
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

make_link() {
  ln -s ../converter/header "$1"
  if [ $? -ne 0 ]; then
    return 1
  fi
  return 0
}

load_params "$@"
if  [ $? -ne 0 ]; then
  cat << EOT
Usage:
  setup.sh <--converter Converter>
Options:
  converter HTTP Response Header Converter
EOT
  exit 1
fi
if [ -e "$HTTP_HEADER_CONV" ]; then
  exit 0
fi

# サブモジュール初期化
init_submodule
if [ $? -ne 0 ]; then
  exit 1
fi

# ビルド
build_converter
if [ $? -ne 0 ]; then
  exit 1
fi

# リンク
make_link "$HTTP_HEADER_CONV"
if [ $? -ne 0 ]; then
  exit 1
fi
exit 0
