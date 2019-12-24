#!/bin/bash

source_file() {
  if [ -f $1 ]; then
    source $1 $2
  else
    echo "Unable to find file $1"
    exit 1
  fi
}

init() {
WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )

source_file "$WORKING_DIR/scripts/get_dependencies.sh" $1
}

help() {
  echo "Work in progress"
  exit 0
}

case $1 in
  wasabi-wallet)
    init $1
    ;;
  *)
    help
    ;;
esac

exit 0
