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

set_tor_options() {
  echo "Checking for Tor connectivity..."
  echo ""

  if OUT=$(curl --socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT \
            https://check.torproject.org/ | cat | grep -m 1 "Congratulations" \
            | xargs) && echo "$OUT" | grep -qs "Congratulations"; then
    echo ""
    echo "Tor connection check: SUCCESSFUL"
    echo "Downloads will occur over Tor!"

    TORSOCKS_PKG="torsocks"
    CURL_TOR_FLAG="--socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT"
    WGET_TOR_FLAG="torsocks"
  fi

  echo ""
  unset OUT
}

init() {
WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )

source_file "$WORKING_DIR/.env"

if ! contains "$SCRIPT_OPTIONS" "--no-tor"; then
  set_tor_options
fi

source_file "$WORKING_DIR/scripts/get_dependencies.sh" $1
source_file "$WORKING_DIR/scripts/project_info.sh" $1
}

check_versions() {
  if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    return 0
  else
    echo "Version $LATEST_VERSION is already installed"
    exit 0
  fi
}

set_download_dir() {
  DOWNLOAD_DIR=$1
}

change_dir() {
  if [ -d $DOWNLOAD_DIR ]; then
    cd $DOWNLOAD_DIR
  elif [ -d $DOWNLOAD_DIR/.. ]; then
    mkdir $DOWNLOAD_DIR && cd $DOWNLOAD_DIR
  elif [ -d ~/Downloads ]; then
    set_download_dir ~/Downloads
    cd $DOWNLOAD_DIR
  else
    set_download_dir ~/Downloads
    mkdir $DOWNLOAD_DIR && cd $DOWNLOAD_DIR
  fi
}

# Format when sending to this method:
# check_for_existing_package $PACKAGE_NAME $DOWNLOAD_URL $PACKAGE_2_NAME $DOWNLOAD_2_URL ...
check_for_existing_package() {
  local ARGUMENTS=( "$@" )
  local COUNTER=0
  for ((i=0; i < $#; i+=2)); do
    if ! [ -f "${ARGUMENTS[$i]}" ]; then
      local DOWNLOAD_STRING+="${ARGUMENTS[$i+1]} "
      let COUNTER++
    fi
  done

  if [ $COUNTER -eq 0 ]; then
    echo "Packages are already downloaded. Re-verifying them!"
    echo ""
    return 0
  else

    if download_files "$DOWNLOAD_STRING" "$PGP_FILE_URL"; then
      return 0
    fi

  fi
}

download_files() {
  echo "Downloading packages to $DOWNLOAD_DIR"
  echo ""

  if $WGET_TOR_FLAG wget $@; then
    echo ""
    return 0
  else
    echo "Something went wrong with the download."

    if [ $WGET_TOR_FLAG != "" ]; then
      echo "Try executing `sudo service tor restart` and re-running the script"
    fi

    echo ""
    exit 1
  fi
}

wasabi() {
#  if check_versions; then
    source_file "$WORKING_DIR/scripts/check_if_running.sh" $1
    set_download_dir ~/Downloads
    change_dir "$DOWNLOAD_DIR"

    if check_for_existing_package "$LATEST_PACKAGE_NAME" "$PACKAGE_DOWNLOAD_URL" \
                               "$LATEST_PACKAGE_NAME.asc" "$SIGNATURE_DOWNLOAD_URL"; then
        echo "verify signatures next"
    fi

#  fi
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
  "wasabi-wallet")
    init $1
    wasabi $1
    ;;
  *)
    help
    ;;
esac

exit 0
