#!/bin/bash

SCRIPT_PACKAGE=$1; shift
SCRIPT_OPTIONS=( $@ )
INIT_COUNTER=0

display_title_message() {
  echo ""
  echo "============================================================================"
  echo ""
  echo "                       Getting $1 for you!"
  echo ""
  echo "============================================================================"
}

# When using this method:
# source_file $FILE_NAME $ARGUMENT_1 $ARGUMENT_2 ...
source_file() {
  local FILE=$1; shift
  local ARGUMENTS=( $@ )

  if [ -f $FILE ]; then

    if source $FILE ${ARGUMENTS[*]}; then
      return 0
    else
      return 1
    fi

  else
    echo "  MESSAGE:  Unable to find file $FILE"
    exit 1
  fi
}

contains() {
  for VALUE in $1; do
    if [ "$VALUE" = "$2" ]; then
      unset VALUE
      return 0
    fi
  done

  unset VALUE
  return 1
}

set_download_dir() {
  unset DOWNLOAD_DIR
  DOWNLOAD_DIR=$1
}

change_dir() {
  if [ -d $DOWNLOAD_DIR ]; then
    cd $DOWNLOAD_DIR
  else
    mkdir -p $DOWNLOAD_DIR && cd $DOWNLOAD_DIR
  fi
}

# When using this method:
# check_for_already_downloaded_package $PACKAGE_1_NAME $DOWNLOAD_1_URL \
#                                      $PACKAGE_2_NAME $DOWNLOAD_2_URL \
#                                      ...
check_for_already_downloaded_package() {
  echo "  MESSAGE:  Checking if package(s) have already been downloaded..."
  echo ""

  local ARGUMENTS=( $@ )
  local COUNTER=0
  for ((i=0; i < $#; i+=2)); do
    if ! [ -z "${ARGUMENTS[$i]}" ]; then
      if ! [ -f "${ARGUMENTS[$i]}" ]; then
        DOWNLOAD_STRING+="${ARGUMENTS[$i+1]} "
        let COUNTER++
      fi
    fi
  done

  if [ $COUNTER -eq 0 ]; then
    echo "  MESSAGE:  Packages are already downloaded"
    echo ""
    return 0
  else
    return 1
  fi
}

# When using this method:
# download_files $DOWNLOAD_URL $DOWNLOAD_2_URL ...
#
# Can also use string concatenation for a single argument
# if URLs are separated by spaces.
download_files() {
  echo "  MESSAGE:  Downloading package(s) to $DOWNLOAD_DIR..."
  echo ""

  if $WGET_TOR_FLAG wget $@; then
    return 0
  else
    echo "  MESSAGE:  Something went wrong with the download"

    if [ $WGET_TOR_FLAG != "" ]; then
      echo "  MESSAGE:  Try executing 'sudo service tor restart' and re-running the script"
    fi

    return 1
  fi
}

check_for_pgp_key() {
  echo "  MESSAGE:  Checking for PGP key..."
  echo ""

  if OUT=$(gpg --list-keys 2>/dev/null) &&
           echo "$OUT" | grep -qs "$PGP_KEY_FINGERPRINT"; then
    unset OUT
    return 0
  else
    unset OUT
    return 1
  fi
}

# When using this method:
# import_pgp_keys_from_file $PGP_FILE_NAME $PGP_FILE_DOWNLOAD_URL
download_and_import_pgp_keys_from_file() {
  echo "  MESSAGE:  Importing PGP key from file..."
  echo ""

  if [ -f $1 ]; then
    mv "$1" "$1.previous"
    echo "  MESSAGE:  $1 already existed and was renamed to $1.previous"
    echo ""
  fi

  if ! download_files "$2"; then
    return 1
  fi

  if gpg --import "$1" 2>/dev/null; then
    rm -rf "$1"
    echo "  MESSAGE:  PGP keys have been successfully imported!"
    echo ""
    return 0
  else
    echo "  MESSAGE:  Failed to import PGP key to verify signature"
    echo "  MESSAGE:  Check gpg settings and re-run the script"
    return 1
  fi
}

# When using this method:
# import_pgp_keys_from_url $KEY_SERVER_URL
import_pgp_keys_from_url() {
  echo "  MESSAGE:  Importing PGP key..."
  echo ""

  if curl -s $CURL_TOR_FLAG $1 | gpg --import 2>/dev/null; then
    echo "  MESSAGE:  PGP keys have been successfully imported!"
    echo ""
    return 0
  else
    echo "  MESSAGE:  Failed to import PGP key to verify signature"
    echo "  MESSAGE:  Check gpg settings and re-run the script"
    return 1
  fi
}

# When using this method:
# verify_pgp_signature $PGP_FILE_NAME
verify_pgp_signature() {
  echo "  MESSAGE:  Verifying PGP signature of $1..."
  echo ""

  if OUT=$(gpg --status-fd 1 --verify "$1" 2>/dev/null) &&
           echo "$OUT" | grep -qs "^\[GNUPG:\] VALIDSIG $PGP_KEY_FINGERPRINT "; then
    echo "  MESSAGE:  PGP signature for $1 was GOOD!"
    echo ""
    unset OUT
    return 0
  else
    echo "  MESSAGE:  PGP signature for $1 was BAD"
    echo "  MESSAGE:  Check gpg settings and re-run the script"
    unset OUT
    return 1
  fi
}

# When using this method:
# verify_sha256sum $SHA256SUM_FILE
#
# The files it will be checking must all be in the same directory as $SHA256SUM_FILE
verify_sha256sum() {
  echo "  MESSAGE:  Verifying sha256sum of $PACKAGE_NAME..."
  echo ""

  if sha256sum --check $1 --ignore-missing 2>/dev/null; then
    echo ""
    echo "  MESSAGE:  $PACKAGE_NAME has been verified and is located"
    echo "  MESSAGE:  in $DOWNLOAD_DIR"
    echo ""
    return 0
  else
    echo ""
    echo "  MESSAGE:  sha256sum check failed for $PACKAGE_NAME"
    echo ""
    return 1
  fi
}

# When using this method:
# clean_up $FILE_1 $FILE_2 ...
#
# Can also send `--sudo` as the first argument to
# make this method call `sudo rm -rf ...`
clean_up() {
  if [ $1 = --sudo ]; then
    local SUDO="sudo"
    shift
  fi

  local ARGUMENTS=( $@ )
  local CLEAN_UP_DIR=$(pwd)

  for ((i=0; i < $#; i++)); do
    if ! [ -z "${ARGUMENTS[$i]}" ]; then
      if [[ -f "${ARGUMENTS[$i]}" || -d "${ARGUMENTS[$i]}" ]]; then
        $SUDO rm -rf "${ARGUMENTS[$i]}"
        echo "  DELETED:  $CLEAN_UP_DIR/${ARGUMENTS[$i]}"
      fi
    fi
  done
}

init() {
  display_title_message $1

  if [ $INIT_COUNTER -eq 0 ]; then

    WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )

    if ! source_file "$WORKING_DIR/.env"; then
      return 1
    fi

    if ! source_file "$WORKING_DIR/scripts/set_tor_options.sh"; then
      return 1
    fi

  let INIT_COUNTER++
  else
  cd $WORKING_DIR
  fi

  if ! source_file "$WORKING_DIR/scripts/get_dependencies.sh" $1; then
    return 1
  fi

  if ! source_file "$WORKING_DIR/scripts/project_info.sh" $1; then
    return 1
  fi

  return 0
}

ckcc_firmware() {
  set_download_dir ~/Coldcard-firmware
  change_dir "$DOWNLOAD_DIR"

  if ! check_for_already_downloaded_package "$PACKAGE_NAME" "$PACKAGE_URL" \
                                            "$SIGNATURE_NAME" "$SIGNATURE_URL"; then

    if ! download_files "$DOWNLOAD_STRING"; then
      unset DOWNLOAD_STRING
      return 1
    fi
    unset DOWNLOAD_STRING

  fi

  if ! check_for_pgp_key; then

    if ! import_pgp_keys_from_url "$PGP_IMPORT_URL"; then
      return 1
    fi

  fi

  if ! verify_pgp_signature "$SIGNATURE_NAME"; then
    return 1
  fi

  if verify_sha256sum "$SIGNATURE_NAME"; then
    clean_up "$SIGNATURE_NAME"
    echo ""
    echo "  MESSAGE:  Please leave $PACKAGE_NAME in"
    echo "  MESSAGE:  $DOWNLOAD_DIR after you have"
    echo "  MESSAGE:  updated your device so this script can tell what"
    echo "  MESSAGE:  version you have installed!"
  else
    clean_up "$SIGNATURE_NAME" "$PACKAGE_NAME"
    return 1
  fi

  return 0
}

ckcc_protocol() {
  local PYTHON_3_VERSION=$(python3 -V | cut -d ' ' -f 2 | cut -d '.' -f 2)

  if [ $PYTHON_3_VERSION -lt 6 ]; then
    echo "  MESSAGE:  Python3 version is less than the minimum required (3.6)."
    return 1
  fi

  if [ "$DRY_RUN" != "--dry-run" ]; then

    local DIST_PACKAGES_DIR="/usr/local/lib/python3.$PYTHON_3_VERSION/dist-packages"

    if [ -f "$DIST_PACKAGES_DIR/ckcc_protocol-$LATEST_VERSION-py3.$PYTHON_3_VERSION.egg" ]; then
      echo "  MESSAGE:  ckcc-protocol is already up to date with version $LATEST_VERSION"
      return 0
    fi

  fi

  set_download_dir ~/Downloads/ckcc-protocol
  change_dir "$DOWNLOAD_DIR"

  if ! check_for_already_downloaded_package "$PACKAGE_NAME" "$PACKAGE_URL"; then

    if ! download_files "$DOWNLOAD_STRING"; then
      unset DOWNLOAD_STRING
      return 1
    fi
    unset DOWNLOAD_STRING

  fi

  if ! tar -xzf $PACKAGE_NAME; then
    echo "  MESSAGE:  Couldn't extract $PACKAGE_NAME. Stopping..."
    return 1
  fi

  cd Coldcard-ckcc-protocol-*

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "  MESSAGE:  '--dry-run' flag set, stopping before installing anything..."
    return 1
  fi

  pip install -r requirements.txt

  if sudo python3 setup.py install; then
    echo ""
    echo "  MESSAGE:  ckcc-protocol-$LATEST_VERSION has been installed successfully!"
    change_dir "$DOWNLOAD_DIR"
    clean_up "--sudo" "$PACKAGE_NAME" "Coldcard-ckcc-protocol-*"
  else
    echo ""
    echo "  MESSAGE:  Installation FAILED."
    return 1
  fi

  return 0
}

wasabi_wallet() {
  if [ "$DRY_RUN" != "--dry-run" ]; then

    if ! source_file "$WORKING_DIR/scripts/is_new_version_available.sh" $CURRENT_VERSION $LATEST_VERSION; then
      return 1
    fi

    if ! source_file "$WORKING_DIR/scripts/check_if_running.sh" $1; then
      return 1
    fi

  fi

  set_download_dir ~/Downloads/wasabi-wallet
  change_dir "$DOWNLOAD_DIR"

  if ! check_for_already_downloaded_package "$PACKAGE_NAME" "$PACKAGE_URL" \
                                            "$SIGNATURE_NAME" "$SIGNATURE_URL"; then

    if ! download_files "$DOWNLOAD_STRING"; then
      unset DOWNLOAD_STRING
      return 1
    fi
    unset DOWNLOAD_STRING

  fi

  if ! check_for_pgp_key; then

    if ! download_and_import_pgp_keys_from_file "$PGP_FILE_NAME" "$PGP_FILE_URL"; then
      return 1
    fi

  fi

  if ! verify_pgp_signature "$SIGNATURE_NAME"; then
    return 1
  fi

  if sudo dpkg $DRY_RUN -i $PACKAGE_NAME; then
    echo ""
    echo "  MESSAGE:  $PACKAGE_NAME has been installed successfully!"
    clean_up "$PACKAGE_NAME" "$SIGNATURE_NAME"
  else
    echo ""
    echo "  MESSAGE:  Something went wrong when installing $PACKAGE_NAME"
    return 1
  fi

  return 0
}

help() {
  echo ""
  echo "$ ./get_latest.sh [PACKAGE-NAME] [OPTION1] [OPTION2] ..."
  echo ""
  echo "[PACKAGE-NAME]:"
  echo ""
  echo "    get-all .  .  .  .  .  Cycles through all of the below listed"
  echo "                           packages & updates/installs them."
  echo ""
  echo "    ckcc-firmware .  .  .  Downloads and verifies the latest"
  echo "                           Coldcard firmware."
  echo ""
  echo "    ckcc-protocol .  .  .  Installs the latest Coldcard protocol"
  echo "                           (primarily needed for Electrum Wallet)."
  echo ""
  echo "    wasabi-wallet .  .  .  Installs the latest .deb package"
  echo "                           of Wasabi Wallet."
  echo ""
  echo "[OPTIONS]:"
  echo ""
  echo "    --dry-run  .  .  .  .  Will not install the packages."
  echo ""
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
  echo "    --only-tor    .  .  .  Will only use tor to download packages."
  echo "                           If the connectivity check fails, the"
  echo "                           script exits."
  echo ""
  echo ""
}

if contains $SCRIPT_OPTIONS "--dry-run"; then
  DRY_RUN="--dry-run"
fi

case $SCRIPT_PACKAGE in
  "get-all")
    if init "ckcc-firmware"; then
      ckcc_firmware "ckcc-firmware"
    fi

    if init "ckcc-protocol"; then
      ckcc_protocol "ckcc-protocol"
    fi

    if init "wasabi-wallet"; then
      wasabi_wallet "wasabi-wallet"
    fi
    ;;
  "ckcc-firmware")
    if init $SCRIPT_PACKAGE; then
      ckcc_firmware $SCRIPT_PACKAGE
    fi
    echo ""
    ;;
  "ckcc-protocol")
    if init $SCRIPT_PACKAGE; then
      ckcc_protocol $SCRIPT_PACKAGE
    fi
    echo ""
    ;;
  "wasabi-wallet")
    if init $SCRIPT_PACKAGE; then
      wasabi_wallet $SCRIPT_PACKAGE
    fi
    echo ""
    ;;
  *)
    help
    ;;
esac

exit 0
