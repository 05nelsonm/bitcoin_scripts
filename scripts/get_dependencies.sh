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

    if ! sudo apt-get update && sudo apt-get install$INSTALL_STRING -y; then
      return 1
    fi

  else
    echo "All needed dependencies are present!"
    echo ""
    return 0
  fi
}

case $1 in
  "no-specified-package")
    shift
    local NEEDED_DEPENDENCIES=( $@ )
    if ! get_dependencies "${NEEDED_DEPENDENCIES[*]}"; then
      return 1
    fi
    ;;
  "ckcc-firmware")
    local NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS_PKG)
    if ! get_dependencies "${NEEDED_DEPENDENCIES[*]}"; then
      return 1
    fi
    ;;
  "ckcc-protocol")
    local NEEDED_DEPENDENCIES=("curl" "wget" "jq" "libusb-1.0-0-dev" \
                               "libudev1" "libudev-dev" "python3" \
                               "python-pip" $TORSOCKS_PKG)
    if ! get_dependencies "${NEEDED_DEPENDENCIES[*]}"; then
      return 1
    fi
    ;;
  "wasabi-wallet")
    local NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS_PKG)
    if ! get_dependencies "${NEEDED_DEPENDENCIES[*]}"; then
      return 1
    fi
    ;;
esac

unset TORSOCKS_PKG
return 0
