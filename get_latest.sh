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

init() {
  WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )
  source_file "$WORKING_DIR/.env"
  source_file "$WORKING_DIR/scripts/set_tor_options.sh"
  source_file "$WORKING_DIR/scripts/get_dependencies.sh" $1
  source_file "$WORKING_DIR/scripts/project_info.sh" $1
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
  else
    download_files "$DOWNLOAD_STRING"
  fi
}

download_files() {
  echo "Downloading packages to $DOWNLOAD_DIR"
  echo ""

  if ! $WGET_TOR_FLAG wget $@; then
    echo "Something went wrong with the download."

    if [ $WGET_TOR_FLAG != "" ]; then
      echo "Try executing 'sudo service tor restart' and re-running the script"
    fi

    exit 1
  fi
}

check_pgp_keys() {
  if OUT=$(gpg --list-keys 2>/dev/null) &&
           echo "$OUT" | grep -qs "$PGP_KEY_FINGERPRINT"; then
    unset OUT
    return 0
  else
    unset OUT
    return 1
  fi
}

import_pgp_keys_from_file() {
  if [ -f $1 ]; then
    mv "$1" "$1.previous"
    echo "$1 already existed and was renamed to $1.previous"
    echo ""
  fi

  download_files "$2"
  if gpg --import "$1" 2>/dev/null; then
    rm -rf "$1"
    echo "PGP keys have been successfully imported"
    echo ""
  else
    echo "Failed to import PGP keys to verify package signatures"
    echo "Check your gpg settings and re-run the script"
    exit 1
  fi
}

verify_signature() {
  if OUT=$(gpg --status-fd 1 --verify "$1" 2>/dev/null) &&
           echo "$OUT" | grep -qs "^\[GNUPG:\] VALIDSIG $PGP_KEY_FINGERPRINT "; then
    echo "PGP signatures were GOOD"
    echo ""
  else
    echo "PGP signature were BAD"
    echo "Check your gpg settings and re-run the script"
    exit 1
  fi
}

clean_up() {
  rm -rf $@
  echo "$DOWNLOAD_DIR has been cleaned up"
}

wasabi() {
  source_file "$WORKING_DIR/scripts/check_versions.sh"
  source_file "$WORKING_DIR/scripts/check_if_running.sh" $1
  set_download_dir ~/Downloads
  change_dir "$DOWNLOAD_DIR"

  check_for_existing_package "$PACKAGE_NAME" "$PACKAGE_URL" \
                             "$SIGNATURE_NAME" "$SIGNATURE_URL"

  if ! check_pgp_keys; then
    import_pgp_keys_from_file "$PGP_FILE_NAME" "$PGP_FILE_URL"
  fi

  verify_signature "$SIGNATURE_NAME"
  if sudo dpkg -i $PACKAGE_NAME; then
    echo ""
    echo "$PACKAGE_NAME has been installed successfully!"
    echo ""
    clean_up "$PACKAGE_NAME" "$SIGNATURE_NAME"
  else
    echo ""
    echo "Something went wrong when installing $PACKAGE_NAME"
  fi
}

help() {
  echo "    ./get_latest.sh [PACKAGE-NAME] [OPTIONS]..."
  echo ""
  echo "[PACKAGE-NAME]:"
  echo "    wasabi-wallet .  .  .  Installs the latest .deb package"
  echo "                           of Wasabi Wallet"
  echo ""
  echo "    ckcc-firmware .  .  .  Downloads and verifies the latest"
  echo "                           Coldcard firmware"
  echo ""
  echo "[OPTIONS]:"
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
  "ckcc-firmware")
    init $1
    ;;
  *)
    help
    ;;
esac

exit 0
