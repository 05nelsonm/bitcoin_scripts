#!/bin/bash

exit_script() {
  echo "An update from $CURRENT_VERSION to $LATEST_VERSION is available"
  echo "Please exit $1 at your earliest convience and re-run this script"
  exit 1
}

case $1 in
  "wasabi-wallet")
    if pgrep wassabee; then
      exit_script $1
    fi
    ;;
esac
