#!/bin/sh
# Copyright (c) 2022 RFull Development
# This source code is managed under the MIT license. See LICENSE in the project root.
load_params() {
  local OPTS REQUIRE_OPTS TEMP

  # オプションを解析
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

  # オプション確認
  if [ -z $DOWNLOAD_URL ]; then
    TEMP="$REQUIRE_OPTS --url"
    REQUIRE_OPTS="$TEMP"
  fi
  if [ -z $HTTP_HEADER_CONV ]; then
    TEMP="$REQUIRE_OPTS --converter"
    REQUIRE_OPTS="$TEMP"
  fi
  if [ -z $LAST_MODIFIED_STORE ]; then
    TEMP="$REQUIRE_OPTS --last-modified"
    REQUIRE_OPTS="$TEMP"
  fi
  if [ -n "$REQUIRE_OPTS" ]; then
    echo "Require options:\n $REQUIRE_OPTS"
    return 1
  fi
  return 0
}

check_update() {
  local HEADER RAW CODE

  if [ -n "$2" ]; then
    HEADER="If-Modified-Since: \"$2\""
    RAW=`curl "$1" --head --header "$HEADER"`
  else
    RAW=`curl "$1" --head`
  fi
  if [ $? -ne 0 ]; then
    echo 'Invalid argument.'
    return 2
  fi
  RESPONSE=`echo "$RAW" | $3`
  CODE=`echo "$RESPONSE" | jq -e -r ".code" | bc`
  if [ $? -ne 0 ]; then
    echo "HTTP Status code is not in response."
    return 2
  elif [ $CODE -eq 304 ]; then
    echo 'Content is not updated.'
    return 1
  elif [ $CODE -ne 200 ]; then
    echo 'Can not download.'
    return 2
  fi
  return 0
}

download() {
  echo "Start downloading from '$1'."
  wget "$1" | bc
  if [ $? -ne 0 ]; then
    echo 'Can not download.'
    return 1
  fi
  echo 'Download completed.'
  return 0
}

load_last_modified() {
  echo "Last Modified read from '$1'."
  LAST_MODIFIED=`cat $LAST_MODIFIED_STORE | tr -d "\r" | tr -d "\n"`
  if [ $? -ne 0 ]; then
    LAST_MODIFIED=
    return 1
  fi
  return 0
  echo "Done."
}

save_last_modified() {
  local LAST_MODIFIED

  echo "Last Modified write to '$2'."
  LAST_MODIFIED=`echo "$1" | jq -e -r ".lastModified"`
  if [ $? -ne 0 ]; then
    echo 'Last modified is not in response.'
    return 1
  fi
  echo "$LAST_MODIFIED" > "$2"
  if [ $? -ne 0 ]; then
    echo "Write failed."
    return 1
  fi
  echo "Done."
  return 0
}

# オプション取得
load_params "$@"
if  [ $? -ne 0 ]; then
  cat << EOT
Usage:
  download.sh <--url URL> <--converter Converter> <-- --last-modified Path>
Options:
  url           Download URL
  converter     HTTP Response Header Converter
  last-modified paContent last modified store path
EOT
  exit 1
fi

# 最終更新日時読み込み
load_last_modified "$LAST_MODIFIED_STORE"

# 更新確認
check_update "$DOWNLOAD_URL" "$LAST_MODIFIED" "$HTTP_HEADER_CONV"
if  [ $? -eq 1 ]; then
  exit 0
elif [ $? -eq 0 ]; then
  exit 0
fi

# ダウンロード
download "$DOWNLOAD_URL"
if  [ $? -ne 0 ]; then
  exit 1
fi

# 最終更新日時保存
save_last_modified "$RESPONSE" "$LAST_MODIFIED_STORE"
exit 0
