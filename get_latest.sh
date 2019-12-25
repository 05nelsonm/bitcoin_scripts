#!/bin/bash

SCRIPT_PACKAGE=$1; shift
SCRIPT_OPTIONS=( $@ )

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
    echo "Unable to find file $FILE"
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

# When using this method:
# check_for_already_downloaded_package $PACKAGE_1_NAME $DOWNLOAD_1_URL \
#                                      $PACKAGE_2_NAME $DOWNLOAD_2_URL \
#                                      ...
check_for_already_downloaded_package() {
  echo "Checking if package(s) have already been downloaded..."
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
    echo "Packages are already downloaded"
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
  echo "Downloading package(s) to $DOWNLOAD_DIR..."
  echo ""

  if $WGET_TOR_FLAG wget $@; then
    return 0
  else
    echo "Something went wrong with the download"

    if [ $WGET_TOR_FLAG != "" ]; then
      echo "Try executing 'sudo service tor restart' and re-running the script"
    fi

    return 1
  fi
}

# $PGP_KEY_FINGERPRINT must be set by scripts/project_info.sh
# to mitigate potential modification of PGP key fingerprints
# that could occur when passing the variable back and forth as
# an argument.
check_pgp_keys() {
  echo "Checking for PGP key..."
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
  echo "Importing PGP key from file..."
  echo ""

  if [ -f $1 ]; then
    mv "$1" "$1.previous"
    echo "$1 already existed and was renamed to $1.previous"
    echo ""
  fi

  if ! download_files "$2"; then
    return 1
  fi

  if gpg --import "$1" 2>/dev/null; then
    rm -rf "$1"
    echo "PGP keys have been successfully imported!"
    echo ""
    return 0
  else
    echo "Failed to import PGP keys to verify package signatures"
    echo "Check gpg settings and re-run the script"
    return 1
  fi
}

# When using this method:
# import_pgp_keys_from_url $KEY_SERVER_URL
import_pgp_keys_from_url() {
  echo "Importing PGP key..."
  echo ""

  if curl -s $CURL_TOR_FLAG $1 | gpg --import 2>/dev/null; then
    echo "PGP keys have been successfully imported!"
    echo ""
    return 0
  else
    echo "Failed to import PGP keys to verify package signatures"
    echo "Check gpg settings and re-run the script"
    return 1
  fi
}

# When using this method:
# verify_pgp_signature $PGP_FILE_NAME
verify_pgp_signature() {
  echo "Verifying PGP signature of $1..."
  echo ""

  if OUT=$(gpg --status-fd 1 --verify "$1" 2>/dev/null) &&
           echo "$OUT" | grep -qs "^\[GNUPG:\] VALIDSIG $PGP_KEY_FINGERPRINT "; then
    echo "PGP signature for $1 was GOOD!"
    echo ""
    unset OUT
    return 0
  else
    echo "PGP signature for $1 was BAD"
    echo "Check gpg settings and re-run the script"
    unset OUT
    return 1
  fi
}

# When using this method:
# verify_sha256sum $SHA256SUM_FILE
#
# The files it will be checking must all be in the same directory as $SHA256SUM_FILE
verify_sha256sum() {
  echo "Verifying sha256sum of $1..."
  echo ""

  if sha256sum --check $1 --ignore-missing 2>/dev/null; then
    echo "$PACKAGE_NAME has been verified and is located in $DOWNLOAD_DIR"
    echo ""
    return 0
  else
    echo "sha256sum check failed for $1"
    echo ""
    return 1
  fi
}

# When using this method:
# clean_up $FILE_1 $FILE_2 ...
clean_up() {
  local ARGUMENTS=( $@ )
  local CLEAN_UP_DIR=$(pwd)

  for ((i=0; i < $#; i++)); do
    if ! [ -z "${ARGUMENTS[$i]}" ]; then
      if [ -f "${ARGUMENTS[$i]}" ]; then
        rm -rf "${ARGUMENTS[$i]}"
        echo "DELETED:  $CLEAN_UP_DIR/${ARGUMENTS[$i]}"
      fi
    fi
  done
}

init() {
  WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )
  if ! source_file "$WORKING_DIR/.env"; then
    return 1
  fi

  if ! source_file "$WORKING_DIR/scripts/set_tor_options.sh"; then
    return 1
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

    if download_files "$DOWNLOAD_STRING"; then
      unset DOWNLOAD_STRING
    else
      return 1
    fi

  fi

  if ! check_pgp_keys; then

    if ! import_pgp_keys_from_url "$PGP_IMPORT_URL"; then
      return 1
    fi

  fi

  if ! verify_pgp_signature "$SIGNATURE_NAME"; then
    return 1
  fi

  if verify_sha256sum "$SIGNATURE_NAME"; then
    clean_up "$SIGNATURE_NAME"
  else
    clean_up "$SIGNATURE_NAME" "$PACKAGE_NAME"
    return 1
  fi

  return 0
}

ckcc_protocol() {
  local PYTHON_3_VERSION=$(python3 -V | cut -d ' ' -f 2 | cut -d '.' -f 2)

  if [ $PYTHON_3_VERSION -gt 5 ]; then
    local DIST-PACKAGES_DIR="/usr/local/lib/python3.$PYTHON_3_VERSION/dist-packages"

    if [ -f "$DIST-PACKAGES_DIR/ckcc_protocol-$LATEST_VERSION-py3.$PYTHON_3_VERSION.egg" ]; then
      echo "ckcc-protocol is already up to date with version $LATEST_VERSION!"
      return 0
    fi

    set_download_dir ~/Downloads
    change_dir "$DOWNLOAD_DIR"

    if ! check_for_already_downloaded_package "$PACKAGE_NAME" "$PACKAGE_URL"; then

      if download_files "$DOWNLOAD_STRING"; then
        unset DOWNLOAD_STRING
      else
        return 1
      fi

    fi

    if tar -xzf $PACKAGE_NAME; then
      cd Coldcard-ckcc-protocol-*

      if pip install -r requirements.txt; then

        if sudo python3 setup.py install; then
          echo ""
          echo "ckcc-protocol-$LATEST_VERSION has been installed successfully!"
          echo ""
          change_dir "$DOWNLOAD_DIR"
        fi

      else
        echo "Needed python dist packages were not installed. Stopping..."
        return 1
      fi

    else
      echo "Couldn't extract $PACKAGE_NAME. Stopping..."
      return 1
    fi

  else
    echo "Python3 version is less than the minimum required (3.6)."
    return 1
  fi

  return 0
}

wasabi_wallet() {
  if ! source_file "$WORKING_DIR/scripts/check_versions.sh" $CURRENT_VERSION $LATEST_VERSION; then
    return 1
  fi

  if ! source_file "$WORKING_DIR/scripts/check_if_running.sh" $1; then
    return 1
  fi

  set_download_dir ~/Downloads
  change_dir "$DOWNLOAD_DIR"

  if ! check_for_already_downloaded_package "$PACKAGE_NAME" "$PACKAGE_URL" \
                                            "$SIGNATURE_NAME" "$SIGNATURE_URL"; then

    if download_files "$DOWNLOAD_STRING"; then
      unset DOWNLOAD_STRING
    else
      return 1
    fi

  fi

  if ! check_pgp_keys; then

    if ! download_and_import_pgp_keys_from_file "$PGP_FILE_NAME" "$PGP_FILE_URL"; then
      return 1
    fi

  fi

  if ! verify_pgp_signature "$SIGNATURE_NAME"; then
    return 1
  fi

  if sudo dpkg -i $PACKAGE_NAME; then
    echo ""
    echo "$PACKAGE_NAME has been installed successfully!"
    echo ""
    clean_up "$PACKAGE_NAME" "$SIGNATURE_NAME"
  else
    echo ""
    echo "Something went wrong when installing $PACKAGE_NAME"
    return 1
  fi

  return 0
}

help() {
  echo "    ./get_latest.sh [PACKAGE-NAME] [OPTIONS]..."
  echo ""
  echo "[PACKAGE-NAME]:"
  echo ""
  echo "    wasabi-wallet .  .  .  Installs the latest .deb package"
  echo "                           of Wasabi Wallet."
  echo ""
  echo "    ckcc-firmware .  .  .  Downloads and verifies the latest"
  echo "                           Coldcard firmware."
  echo ""
  echo "    ckcc-protocol .  .  .  Installs the latest Coldcard protocol"
  echo "                           (primarily needed for Electrum Wallet)."
  echo ""
  echo "[OPTIONS]:"
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
  echo "    --only-tor    .  .  .  This flag will only use tor to download"
  echo "                           packages. If the connectivity check fails,"
  echo "                           the script exits."
}

case $SCRIPT_PACKAGE in
  "ckcc-firmware")
    if init $SCRIPT_PACKAGE; then
      ckcc_firmware $SCRIPT_PACKAGE
    fi
    ;;
  "ckcc-protocol")
    if init $SCRIPT_PACKAGE; then
      ckcc_protocol $SCRIPT_PACKAGE
    fi
    ;;
  "wasabi-wallet")
    if init $SCRIPT_PACKAGE; then
      wasabi_wallet $SCRIPT_PACKAGE
    fi
    ;;
  *)
    help
    ;;
esac

exit 0
