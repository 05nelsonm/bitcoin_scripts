#!/bin/bash

get_dependencies() {
  echo "Checking for needed dependencies"
  echo ""

  counter=0

  for PACKAGE in $1; do
    if ! dpkg -l $PACKAGE > /dev/null 2>&1; then
      INSTALL_STRING+=" $PACKAGE"
      let counter++
    fi
  done
  unset PACKAGE

  if [ $counter -gt 0 ]; then
    sudo apt-get update && sudo apt-get install$INSTALL_STRING -y
  fi
  unset counter INSTALL_STRING PACKAGE
}

if command -v tor 1>/dev/null; then
  TORSOCKS_PKG="torsocks"
fi

case $1 in
  "wasabi-wallet")
    NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS_PKG)
    get_dependencies "${NEEDED_DEPENDENCIES[*]}"
    ;;
  *)
    echo "try the --help flag to see accepted script inputs"
    exit 1
    ;;
esac

unset TORSOCKS_PKG NEEDED_DEPENDENCIES
