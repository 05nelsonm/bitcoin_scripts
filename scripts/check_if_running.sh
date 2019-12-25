#!/bin/bash

stop_install() {
  echo "An update to $LATEST_VERSION is available"
  echo "Please exit $1 at your earliest convience and re-run this script"
}

case $1 in
  "wasabi-wallet")
    if pgrep wassabee; then
      stop_install $1
      return 1
    fi
    ;;
esac

return 0
