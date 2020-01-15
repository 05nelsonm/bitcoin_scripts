#!/bin/bash

USER_DEFINED_PACKAGE=$1; shift
USER_DEFINED_OPTIONS=( $@ )

SCRIPT_AVAILABLE_PACKAGES=("get-all" "bitcoin-core" "ckcc-firmware" "ckcc-protocol" "electrs" "electrum-wallet" \
                           "lnd" "samourai-dojo" "tor" "wasabi-wallet" "zap-desktop")

WORKING_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) >/dev/null && pwd )

source_file() {
# Extends `source` by adding logic checks and returns
#
# When using this method:
# source_file $FILE_NAME $ARGUMENT_1 $ARGUMENT_2 ...

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

initialize_script() {
# Initializes things that only need to be called once every time the script is run

  if ! source_file "$WORKING_DIR/scripts/functions.sh"; then
    echo "  MESSAGE:  Could not source necessary file:"
    echo "  MESSAGE:  $WORKING_DIR/scripts/functions.sh"
    echo "  MESSAGE:  even though it exists..."
    exit 1
  fi

  if ! source_file "$WORKING_DIR/.env"; then
    echo "  MESSAGE:  Could not source necessary file:"
    echo "  MESSAGE:  $WORKING_DIR/.env"
    echo "  MESSAGE:  even though it exists..."
    exit 1
  fi

  set_script_option_variables

  if ! command -v curl 1>/dev/null; then

    if ! get_dependencies "no-specified-script-package" "curl"; then
      echo "  MESSAGE:  Curl needs to be installed to go any further..."
      exit 1
    fi

  fi

  if [ "$NO_TOR" != "--no-tor" ]; then
    set_tor_options
  fi

  local NEEDED_DEPENDENCIES=("wget" "gpg" "jq" $TORSOCKS)
  if ! get_dependencies "no-specified-script-package" ${NEEDED_DEPENDENCIES[*]}; then
    echo "  MESSAGE:  ${NEEDED_DEPENDENCIES[*]} need to be installed to go any further..."
    exit 1
  fi
}

initialize_defined_package() {
# Initializes things that need to be called for each individual package

  local DEFINED_PACKAGE=$1

  cd $WORKING_DIR

  display_title_message $DEFINED_PACKAGE

  if ! source_file "$WORKING_DIR/scripts/project_info.sh" $DEFINED_PACKAGE; then
    return 1
  fi

  return 0
}

ckcc_firmware() {
  set_download_dir ~/Coldcard-firmware

  if ! change_dir "$DOWNLOAD_DIR"; then
    return 1
  fi

  if ! check_for_already_downloaded_package "$PACKAGE_NAME" "$PACKAGE_URL" \
                                            "$SIGNATURE_FILE_NAME" "$SIGNATURE_FILE_URL"; then

    if ! download_files "$DOWNLOAD_STRING"; then
      unset DOWNLOAD_STRING
      return 1
    fi
    unset DOWNLOAD_STRING

  fi

  if ! check_if_pgp_key_exists_in_keyring "$PGP_KEY_FINGERPRINT"; then

    if ! import_pgp_keys_from_url "$PGP_IMPORT_URL"; then
      return 1
    fi

  fi

  if ! verify_pgp_signature "$SIGNATURE_FILE_NAME" "$PGP_KEY_FINGERPRINT"; then
    return 1
  fi

  if verify_sha256sum "$SIGNATURE_FILE_NAME"; then
    clean_up "$DOWNLOAD_DIR/$SIGNATURE_FILE_NAME"
    echo ""
    echo "  MESSAGE:  Please leave $PACKAGE_NAME in"
    echo "  MESSAGE:  $DOWNLOAD_DIR after you have"
    echo "  MESSAGE:  updated your device so this script can tell what"
    echo "  MESSAGE:  version you have installed!"
  else
    clean_up "$DOWNLOAD_DIR/$SIGNATURE_FILE_NAME" "$DOWNLOAD_DIR/$PACKAGE_NAME"
    return 1
  fi

  return 0
}

ckcc_protocol() {
  local DEFINED_PACKAGE=$1

  if ! get_dependencies $DEFINED_PACKAGE; then
    return 1
  fi

  local PYTHON_3_VERSION=$(python3 -V | cut -d ' ' -f 2 | cut -d '.' -f 2)

  if [ $PYTHON_3_VERSION -lt 6 ]; then
    echo "  MESSAGE:  Python3 version is less than the minimum required (3.6)."
    return 1
  fi

  if [ "$DRY_RUN" != "--dry-run" ]; then

    local DIST_PACKAGES_DIR="/usr/local/lib/python3.$PYTHON_3_VERSION/dist-packages"

    if [ -f "$DIST_PACKAGES_DIR/ckcc_protocol-$LATEST_VERSION-py3.$PYTHON_3_VERSION.egg" ]; then
      echo "  MESSAGE:  Already up to date with version $LATEST_VERSION"
      return 0
    fi

  fi

  set_download_dir ~/Downloads/ckcc-protocol

  if ! change_dir "$DOWNLOAD_DIR"; then
    return 1
  fi

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

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "  MESSAGE:  '--dry-run' flag set, stopping before installing anything..."
    return 1
  fi

  cd Coldcard-ckcc-protocol-*

  pip install -r requirements.txt

  if sudo python3 setup.py install; then
    echo ""
    echo "  MESSAGE:  ckcc-protocol-$LATEST_VERSION has been installed successfully!"
    cd $WORKING_DIR
    clean_up "--sudo" "$DOWNLOAD_DIR"
  else
    echo ""
    echo "  MESSAGE:  Installation FAILED."
    return 1
  fi

  return 0
}

wasabi_wallet() {
  local DEFINED_PACKAGE=$1

  if [ "$DRY_RUN" != "--dry-run" ]; then

    if ! compare_current_with_latest_version $CURRENT_VERSION $LATEST_VERSION; then
      return 1
    fi

    if ! check_if_running $DEFINED_PACKAGE; then
      return 1
    fi

  fi

  set_download_dir ~/Downloads/wasabi-wallet

  if ! change_dir "$DOWNLOAD_DIR"; then
    return 1
  fi

  if ! check_for_already_downloaded_package "$PACKAGE_NAME" "$PACKAGE_URL" \
                                            "$SIGNATURE_FILE_NAME" "$SIGNATURE_FILE_URL"; then

    if ! download_files "$DOWNLOAD_STRING"; then
      unset DOWNLOAD_STRING
      return 1
    fi
    unset DOWNLOAD_STRING

  fi

  if ! check_if_pgp_key_exists_in_keyring "$PGP_KEY_FINGERPRINT"; then

    if ! download_and_import_pgp_keys_from_file "$PGP_FILE_NAME" "$PGP_FILE_URL"; then
      return 1
    fi

  fi

  if ! verify_pgp_signature "$SIGNATURE_FILE_NAME" "$PGP_KEY_FINGERPRINT"; then
    return 1
  fi

  if sudo dpkg $DRY_RUN -i $PACKAGE_NAME; then
    echo ""

    if [ "$DRY_RUN" = "--dry-run" ];then
      echo "  MESSAGE:  $PACKAGE_NAME was not installed because --dry-run is set"
    else
      echo "  MESSAGE:  $PACKAGE_NAME has been installed successfully!"
    fi

    cd $WORKING_DIR
    clean_up "$DOWNLOAD_DIR"
  else
    echo ""
    echo "  MESSAGE:  Something went wrong when installing $PACKAGE_NAME"
    return 1
  fi

  return 0
}

help() {
  echo ""
  echo "This script downloads, verifies signatures of, & installs packages for you."
  echo ""
  echo ""
  echo "$ ./get_latest.sh [PACKAGE-NAME] [OPTION1] [OPTION2] ..."
  echo ""
  echo "[PACKAGE-NAME]"
  echo ""
#           Get All
  echo "    ${SCRIPT_AVAILABLE_PACKAGES[0]} .  .  .  .  . +  Cycles through all of the below listed"
  echo "                          +  packages & updates/installs them."
  echo ""
#           Coldcard Firmware
  echo "    ${SCRIPT_AVAILABLE_PACKAGES[2]} .  .  . +  Downloads the latest Coldcard firmware."
  echo "                          +"
  echo "                          +  Running this will *ALWAYS* re-verify the"
  echo "                          +  package for you if it already exists."
  echo ""
#           Coldcard Protocol
  echo "    ${SCRIPT_AVAILABLE_PACKAGES[3]} .  .  . +  Installs the latest Coldcard protocol"
  echo "                          +  (primarily needed for Electrum Wallet)."
  echo ""
#           Wasabi Wallet
  echo "    ${SCRIPT_AVAILABLE_PACKAGES[9]} .  .  . +  Installs the latest .deb package"
  echo "                          +  of Wasabi Wallet."
  echo ""
  echo "[OPTIONS]"
  echo ""
  echo "    --dry-run  .  .  .  . +  Will not install or delete downloaded"
  echo "                          +  packages."
  echo "                          +"
  echo "                          +  Can also be used just to download and"
  echo "                          +  verify the latest package(s)."
  echo ""
  echo "    --no-tor   .  .  .  . +  By default, if Tor is installed a"
  echo "                          +  connectivity check will be performed."
  echo "                          +"
  echo "                          +  If it passes, the script will download"
  echo "                          +  things over Tor; if it fails, it falls"
  echo "                          +  back to downloading things over clearnet."
  echo "                          +"
  echo "                          +  Setting this option will skip the check"
  echo "                          +  entirely & download things over clearnet."
  echo ""
  echo "    --only-tor    .  .  . +  Will *ONLY* use Tor to download packages."
  echo "                          +  If the connectivity check fails, the"
  echo "                          +  script exits."
  echo ""
  echo ""
}

##                                0           1               2               3            4            5
## SCRIPT_AVAILABLE_PACKAGES=("get-all" "bitcoin-core" "ckcc-firmware" "ckcc-protocol" "electrs" "electrum-wallet" \
##                            "lnd" "samourai-dojo" "tor" "wasabi-wallet" "zap-desktop")
##                              6          7          8          9             10

case $USER_DEFINED_PACKAGE in

  #Get All
  "${SCRIPT_AVAILABLE_PACKAGES[0]}")
    initialize_script

    # Coldcard Firmware
    if initialize_defined_package "${SCRIPT_AVAILABLE_PACKAGES[2]}"; then
      ckcc_firmware
    fi

    # Coldcard Protocol
    if initialize_defined_package "${SCRIPT_AVAILABLE_PACKAGES[3]}"; then
      ckcc_protocol "${SCRIPT_AVAILABLE_PACKAGES[3]}"
    fi

    # Wasabi Wallet
    if initialize_defined_package "${SCRIPT_AVAILABLE_PACKAGES[9]}"; then
      wasabi_wallet "${SCRIPT_AVAILABLE_PACKAGES[9]}"
    fi
    ;;

  # Coldcard Firmware
  "${SCRIPT_AVAILABLE_PACKAGES[2]}")
    initialize_script

    if initialize_defined_package $USER_DEFINED_PACKAGE; then
      ckcc_firmware
    fi
    echo ""
    ;;

  # Coldcard Protocol
  "${SCRIPT_AVAILABLE_PACKAGES[3]}")
    initialize_script

    if initialize_defined_package $USER_DEFINED_PACKAGE; then
      ckcc_protocol $USER_DEFINED_PACKAGE
    fi
    echo ""
    ;;

  # Wasabi Wallet
  "${SCRIPT_AVAILABLE_PACKAGES[9]}")
    initialize_script

    if initialize_defined_package $USER_DEFINED_PACKAGE; then
      wasabi_wallet $USER_DEFINED_PACKAGE
    fi
    echo ""
    ;;

  *)
    help
    ;;

esac

exit 0
