#!/bin/bash

get_dependencies() {
  echo "Checking for needed dependencies..."
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
  else
    echo "All needed packages present"
    echo ""
  fi
}

case $1 in
  "ckcc-firmware")
    local NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS_PKG)
    get_dependencies "${NEEDED_DEPENDENCIES[*]}"
    ;;
  "ckcc-protocol")
    local NEEDED_DEPENDENCIES=("curl" "wget" "jq" "libusb-1.0-0-dev" \
                               "libudev1" "libudev-dev" "python3" \
                               "python-pip" $TORSOCKS_PKG)
    get_dependencies "${NEEDED_DEPENDENCIES[*]}"
    ;;
  "wasabi-wallet")
    local NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS_PKG)
    get_dependencies "${NEEDED_DEPENDENCIES[*]}"
    ;;
esac

unset TORSOCKS_PKG
