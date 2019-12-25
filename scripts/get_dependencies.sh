#!/bin/bash

get_dependencies() {
  echo "Checking for needed dependencies"
  echo ""

  local COUNTER=0

  for PACKAGE in $1; do
    if ! dpkg -l $PACKAGE > /dev/null 2>&1; then
      local INSTALL_STRING+=" $PACKAGE"
      let counter++
    fi
  done
  unset PACKAGE

  if [ $COUNTER -gt 0 ]; then
    sudo apt-get update && sudo apt-get install$INSTALL_STRING -y
  fi
}

case $1 in
  "wasabi-wallet")
    local NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS_PKG)
    get_dependencies "${NEEDED_DEPENDENCIES[*]}"
    ;;
esac

unset TORSOCKS_PKG
