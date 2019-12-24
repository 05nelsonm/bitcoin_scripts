#!/bin/bash

SCRIPT_OPTIONS=($2 $3)

source_file() {
  if [ -f $1 ]; then
    source $1 $2
  else
    echo "Unable to find file $1"
    exit 1
  fi
}

contains() {
  for VALUE in $1; do
    if [ $VALUE = $2 ]; then
      unset VALUE
      return 0
    fi
  done

  unset VALUE
  return 1
}

init() {
WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )

source_file "$WORKING_DIR/.env"

if ! contains "$SCRIPT_OPTIONS" "--no-tor"; then
  source_file "$WORKING_DIR/scripts/set_tor_options.sh"
fi

source_file "$WORKING_DIR/scripts/get_dependencies.sh" $1
}

help() {
  echo "    ./get_latest.sh [PACKAGE-NAME] [OPTIONS]..."
  echo ""
  echo "    [PACKAGE-NAME]:"
  echo "    wasabi-wallet .  .  .  Installs the latest .deb package"
  echo "                           of Wasabi Wallet"
  echo ""
  echo "    [OPTIONS]:"
  echo "    --no-tor   .  .  .  .  By default downloads occur over"
  echo "                           Tor if it is found and passes a"
  echo "                           connectivity check."
  echo ""
  echo "                           Setting this option will skip that"
  echo "                           and make downloads over clearnet."

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
