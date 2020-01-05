#!/bin/bash

# Functions are sorted alphabetically by name to make locating them easier.


### A ###############################################################################
#####################################################################################

array_contains() {
# Checks if an array contains a value
#
# When using this function:
# array_contains $ARRAY $SEARCH_FOR

  local ARRAY=$1
  local SEARCH_FOR=$2

  for VALUE in $ARRAY; do
    if [ "$VALUE" = "$SEARCH_FOR" ]; then
      unset VALUE
      return 0
    fi
  done

  unset VALUE
  return 1
}

### B ###############################################################################
#####################################################################################

### C ###############################################################################
#####################################################################################

change_dir() {
  local DIRECTORY=$1

  if [ "$DIRECTORY" != "" ]; then

    if [ -d $DIRECTORY ]; then
      cd $DIRECTORY
    else
      mkdir -p $DIRECTORY && cd $DIRECTORY
    fi

    return 0
  else
    return 1
  fi
}

check_if_pgp_key_exists_in_keyring() {
  local FINGERPRINT=$1

  echo "  MESSAGE:  Checking for PGP key in your keyring..."
  echo ""

  if OUT=$(gpg --list-keys 2>/dev/null) &&
           echo "$OUT" | grep -qs "$FINGERPRINT"; then
    unset OUT
    return 0
  else
    unset OUT
    return 1
  fi
}

check_if_running() {
  local DEFINED_PACKAGE=$1

  case $DEFINED_PACKAGE in

    # Wasabi Wallet
    "${SCRIPT_AVAILABLE_PACKAGES[9]}")
      if pgrep wassabee; then
        stop_install_message $DEFINED_PACKAGE
        return 1
      fi
      ;;

    *)
      echo "  MESSAGE:  $DEFINED_PACKAGE is not an option available for this function."
      return 1
      ;;

  esac

  return 0
}

check_for_already_downloaded_package() {
# If package isn't already downloaded, builds a string of the download urls
# that can be later sent to the download_files function
#
# When using this function:
# check_for_already_downloaded_package $PACKAGE_1_NAME $DOWNLOAD_1_URL \
#                                      $PACKAGE_2_NAME $DOWNLOAD_2_URL \
#                                      ...

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

clean_up() {
# When using this function:
# clean_up $FILE_1 $FILE_2 $DIRECTORY_A $DIRECTORY_B...
#
# Can also send `--sudo` as the first argument to
# make this method call `sudo rm -rf ...`

  if [ "$DRY_RUN" != "--dry-run" ]; then

    if [ "$1" = "--sudo" ]; then
      local SUDO="sudo"
      shift
    fi

    local ARGUMENTS=( $@ )

    for ((i=0; i < $#; i++)); do
      if ! [ -z "${ARGUMENTS[$i]}" ]; then
        if [[ -f "${ARGUMENTS[$i]}" || -d "${ARGUMENTS[$i]}" ]]; then
          $SUDO rm -rf "${ARGUMENTS[$i]}"
          echo "  DELETED:  ${ARGUMENTS[$i]}"
        fi
      fi
    done

  fi
}

compare_current_with_latest_version() {
  local CURRENT=$1
  local LATEST=$2

  if [ "$CURRENT" != "$LATEST" ]; then
    echo "  MESSAGE:  An update to version $LATEST is available!"
    echo ""
    return 0
  else
    echo "  MESSAGE:  Already up to date with version $LATEST!"
    return 1
  fi
}

### D ###############################################################################
#####################################################################################

display_title_message() {
  local DEFINED_PACKAGE=$1

  echo ""
  echo "============================================================================"
  echo ""
  echo "                       Getting $DEFINED_PACKAGE for you!"
  echo ""
  echo "============================================================================"
  echo ""
  echo "                  Press 'ctrl + c' to stop at any time"
  echo ""
}

download_and_import_pgp_keys_from_file() {
# When using this function:
# download_and_import_pgp_keys_from_file $PGP_FILE_NAME $PGP_FILE_DOWNLOAD_URL

  local FILE=$1
  local DOWNLOAD_URL=$2

  echo "  MESSAGE:  Importing PGP key from file..."
  echo ""

  if [ -f $FILE ]; then
    mv "$FILE" "$FILE.previous"
    echo "  MESSAGE:  $FILE already existed and was renamed to $FILE.previous"
    echo ""
  fi

  if ! download_files "$DOWNLOAD_URL"; then
    return 1
  fi

  if gpg --import "$FILE" 2>/dev/null; then
    echo "  MESSAGE:  PGP keys have been successfully imported!"
    echo ""
    clean_up "$FILE"
    return 0
  else
    echo "  MESSAGE:  Failed to import PGP key to verify signature"
    echo "  MESSAGE:  Check gpg settings and re-run the script"
    return 1
  fi
}

download_files() {
# When using this function:
# download_files $DOWNLOAD_URL $DOWNLOAD_2_URL ...
#
# Can also use string concatenation for a single argument
# if URLs are separated by spaces.

  local DOWNLOAD_URLS=( $@ )
  local CURRENT_DIR=$(pwd)

  echo "  MESSAGE:  Downloading package(s) to $CURRENT_DIR..."
  echo ""

  if $TORSOCKS wget "$DOWNLOAD_URLS"; then
    return 0
  else
    echo "  MESSAGE:  Something went wrong with the download"

    if [ "$TORSOCKS" = "torsocks" ]; then
      echo "  MESSAGE:  Try executing 'sudo service tor restart' and re-running the script"
    fi

    return 1
  fi
}

### E ###############################################################################
#####################################################################################

### F ###############################################################################
#####################################################################################

### G ###############################################################################
#####################################################################################

get_dependencies() {
  local DEFINED_PACKAGE=$1

  case $DEFINED_PACKAGE in

    "no-specified-script-package")
      shift
      local NEEDED_DEPENDENCIES=( $@ )
      ;;

    # Coldcard Firmware
    "${SCRIPT_AVAILABLE_PACKAGES[2]}")
      local NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS)
      ;;

    # Coldcard Protocol
    "${SCRIPT_AVAILABLE_PACKAGES[3]}")
      local NEEDED_DEPENDENCIES=("curl" "wget" "jq" "libusb-1.0-0-dev" \
                                 "libudev1" "libudev-dev" "python3" \
                                 "python-pip" $TORSOCKS)
      ;;

    # Wasabi Wallet
    "${SCRIPT_AVAILABLE_PACKAGES[9]}")
      local NEEDED_DEPENDENCIES=("curl" "wget" "gpg" "jq" $TORSOCKS)
      ;;

    *)
      echo "  MESSAGE:  $1 is not an option available for this function."
      return 1
      ;;

  esac

  echo "  MESSAGE:  Checking for needed dependencies..."
  echo ""

  local COUNTER=0

  for DEPENDENCY in ${NEEDED_DEPENDENCIES[*]}; do
    if ! dpkg -l $DEPENDENCY > /dev/null 2>&1; then
      local INSTALL_STRING+=" $DEPENDENCY"
      let COUNTER++
    fi
  done
  unset DEPENDENCY

  if [ $COUNTER -gt 0 ]; then

    if ! sudo apt-get update; then
      echo "  MESSAGE:  Could not execute 'sudo apt-get update'"
      return 1
    fi

    if ! sudo apt-get install$INSTALL_STRING -y; then
      echo "  MESSAGE:  installation of$INSTALL_STRING failed"
      return 1
    fi

    return 0

  else
    echo "  MESSAGE:  All needed dependencies are present!"
    echo ""
    return 0
  fi
}

### H ###############################################################################
#####################################################################################

### I ###############################################################################
#####################################################################################

import_pgp_keys_from_url() {
# When using this function:
# import_pgp_keys_from_url $KEY_SERVER_URL

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

### J ###############################################################################
#####################################################################################

### K ###############################################################################
#####################################################################################

### L ###############################################################################
#####################################################################################

### M ###############################################################################
#####################################################################################

### N ###############################################################################
#####################################################################################

### O ###############################################################################
#####################################################################################

### P ###############################################################################
#####################################################################################

### Q ###############################################################################
#####################################################################################

### R ###############################################################################
#####################################################################################

### S ###############################################################################
#####################################################################################

set_download_dir() {
  unset DOWNLOAD_DIR
  DOWNLOAD_DIR=$1
}

set_script_option_variables() {
  if array_contains $USER_DEFINED_OPTIONS "--dry-run"; then
    DRY_RUN="--dry-run"
  fi

  if array_contains $USER_DEFINED_OPTIONS "--no-tor"; then
    NO_TOR="--no-tor"
  fi

  if array_contains $USER_DEFINED_OPTIONS "--only-tor"; then
    ONLY_TOR="--only-tor"
  fi
}

set_tor_options() {
  if command -v tor 1>/dev/null; then
    echo "  MESSAGE:  Checking for Tor connectivity..."
    echo ""

    if ! command -v curl 1>/dev/null; then

      if ! get_dependencies "no-specified-script-package" "curl"; then
        echo "  MESSAGE:  Curl needs to be installed to go any further..."
        exit 1
      fi

    fi

    if OUT=$(curl --socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT \
             https://check.torproject.org/ | cat | grep -m 1 "Congratulations" \
             | xargs) && echo "$OUT" | grep -qs "Congratulations"; then
      echo ""
      echo "  MESSAGE:  Tor connectivity check: SUCCESSFUL"
      echo "  MESSAGE:  Downloads will occur over Tor!"

      TORSOCKS="torsocks"
      CURL_TOR_FLAG="--socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT"
    elif [ "$ONLY_TOR" = "--only-tor" ]; then
      echo ""
      echo "  MESSAGE:  Tor connectivity check: FAILED"
      echo "  MESSAGE:  Exiting because flag --only-tor was expressed"
      exit 1
    else
      echo ""
      echo "  MESSAGE:  Tor connectivity check: FAILED"
      echo "  MESSAGE:  Downloads will occur over clearnet"
    fi

    echo ""
    unset OUT

  elif [ "$ONLY_TOR" = "--only-tor" ]; then
    echo ""
    echo "  MESSAGE:  Tor is not installed"
    echo "  MESSAGE:  Exiting because flag --only-tor was expressed"
    exit 1
  fi
}

stop_install_message() {
  echo "  MESSAGE:  An update to $LATEST_VERSION is available."
  echo "  MESSAGE:  Please exit $1 at your earliest"
  echo "  MESSAGE:  convience and re-run this script"
}

### T ###############################################################################
#####################################################################################

### U ###############################################################################
#####################################################################################

### V ###############################################################################
#####################################################################################

verify_pgp_signature() {
# When using this function:
# verify_pgp_signature $SIGNATURE_FILE_NAME $PGP_KEY_FINGERPRINT

  local FILE=$1
  local FINGERPRINT=$2

  echo "  MESSAGE:  Verifying PGP signature of $1..."
  echo ""

  if OUT=$(gpg --status-fd 1 --verify "$FILE" 2>/dev/null) &&
           echo "$OUT" | grep -qs "^\[GNUPG:\] VALIDSIG $FINGERPRINT "; then
    echo "  MESSAGE:  PGP signature for $FILE was GOOD!"
    echo ""
    unset OUT
    return 0
  else
    echo "  MESSAGE:  PGP signature for $FILE was BAD"
    echo "  MESSAGE:  Check gpg settings and re-run the script"
    unset OUT
    return 1
  fi
}

verify_sha256sum() {
# When using this function:
# verify_sha256sum $SHA256SUM_FILE
#
# The files it will be checking must all be in the same directory as $SHA256SUM_FILE

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

### W ###############################################################################
#####################################################################################

### X ###############################################################################
#####################################################################################

### Y ###############################################################################
#####################################################################################

### Z ###############################################################################
#####################################################################################
