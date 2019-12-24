#!/bin/bash

### Help Flag Block ################################################
if [[ $1 = "help" || $1 = "--help" || $1 = "-h" ]]; then
  echo "work in progress"
  exit 0
fi
####################################################################

WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )

source_file() {
  if [ -f $1 ]; then
    source $1 $2
  else
    echo "Unable to find file $1"
    exit 1
  fi
}

source_file "$WORKING_DIR/scripts/get_dependencies.sh" $1

exit 0
