#!/bin/bash

SCRIPT_OPTIONS=($2 $3 $4 $5 $6)

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
  if command -v tor 1>/dev/null; then
    echo "Checking for Tor connectivity..."
    echo ""

    if OUT=$(curl --socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT \
              https://check.torproject.org/ | cat | grep -m 1 "Congratulations" \
              | xargs) && echo "$OUT" | grep -qs "Congratulations"; then
      echo ""
      echo "Tor connectivity check: SUCCESSFUL"
      echo "Downloads will occur over Tor!"

      TORSOCKS_PKG="torsocks"
      CURL_TOR_FLAG="--socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT"
      WGET_TOR_FLAG="torsocks"
    elif contains "$SCRIPT_OPTIONS" "--only-tor"; then
      echo ""
      echo "Tor connectivity check: FAILED"
      echo "Exiting because flag --only-tor was expressed"
      exit 1
    else
      echo ""
      echo "Tor connectivity check: FAILED"
      echo "Downloads will occur over clearnet"
    fi

    echo ""
    unset OUT
  elif contains "$SCRIPT_OPTIONS" "--only-tor"; then
    echo ""
    echo "Tor is not installed"
    echo "Exiting because flag --only-tor was expressed"
    exit 1
  fi
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
      if ! [ -z "${ARGUMENTS[$i]}" ]; then
        local DOWNLOAD_STRING+="${ARGUMENTS[$i+1]} "
        let COUNTER++
      fi
    fi
  done

  if [ $COUNTER -eq 0 ]; then
    echo "Packages are already downloaded. Re-verifying them!"
    echo ""
    return 0
  else

    if download_files "$DOWNLOAD_STRING"; then
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

check_pgp_keys() {
  if OUT=$(gpg --list-keys 2>/dev/null) &&
           echo "$OUT" | grep -qs "$PGP_KEY_FINGERPRINT"; then
    return 0
  else
    IMPORT_PGP_NEEDED="yes"
    return 1
  fi
}

wasabi() {
  if check_versions; then
    source_file "$WORKING_DIR/scripts/check_if_running.sh" $1
    set_download_dir ~/Downloads
    change_dir "$DOWNLOAD_DIR"

    if ! check_pgp_keys; then
        local PGP_FILE_NAME_TEMP="$PGP_FILE_NAME"
        local PGP_FILE_URL_TEMP="$PGP_FILE_URL"
    fi

    if check_for_existing_package "$LATEST_PACKAGE_NAME" "$PACKAGE_DOWNLOAD_URL" \
                                  "$LATEST_PACKAGE_NAME.asc" "$SIGNATURE_DOWNLOAD_URL" \
                                  "$PGP_FILE_NAME_TEMP" "$PGP_FILE_URL_TEMP"; then

      if [ "$IMPORT_PGP_NEEDED" = "yes" ]; then
        #import_pgp_keys_from_file "$PGP_FILE_NAME"
        unset IMPORT_PGP_NEEDED
      fi

      echo "verify signatures next"
    fi

  fi
}

help() {
  echo "    ./get_latest.sh [PACKAGE-NAME] [OPTIONS]..."
  echo ""
  echo "    [PACKAGE-NAME]:"
  echo "    wasabi-wallet .  .  .  Installs the latest .deb package"
  echo "                           of Wasabi Wallet"
  echo ""
  echo "    [OPTIONS]:"
  echo "    --no-tor   .  .  .  .  By default, if Tor is found a"
  echo "                           connectivity check will be done."
  echo ""
  echo "                           If it passes, the script will download"
  echo "                           over Tor. If it fails, it falls back"
  echo "                           to downloading over clearnet."
  echo ""
  echo "                           Setting this option will skip the check"
  echo "                           and make downloads over clearnet."
  echo ""
  echo "    --only-tor    .  .  .  This flag will only use tor to download"
  echo "                           packages. If the connectivity check fails,"
  echo "                           the script exits."

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
