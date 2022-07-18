#!/bin/sh
# Copyright (c) 2022 RFull Development
# This source code is managed under the MIT license. See LICENSE in the project root.
log_info() {
  echo "$1"
}

log_error() {
  echo "$1" >&2
}
