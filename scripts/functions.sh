#!/bin/bash

display_title_message() {
  echo ""
  echo "============================================================================"
  echo ""
  echo "                       Getting $1 for you!"
  echo ""
  echo "============================================================================"
  echo ""
  echo "                  Press 'ctrl + c' to stop at any time"
  echo ""
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

set_script_option_variables() {
  if contains $SCRIPT_OPTIONS "--dry-run"; then
    DRY_RUN="--dry-run"
  fi

  if contains $SCRIPT_OPTIONS "--no-tor"; then
    NO_TOR="--no-tor"
  fi

  if contains $SCRIPT_OPTIONS "--only-tor"; then
    ONLY_TOR="--only-tor"
  fi
}

get_dependencies() {
  case $1 in
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
      echo "$1 is not an option available for this function."
      return 1
      ;;
  esac

  echo "  MESSAGE:  Checking for needed dependencies..."
  echo ""

  local COUNTER=0

  for PACKAGE in ${NEEDED_DEPENDENCIES[*]}; do
    if ! dpkg -l $PACKAGE > /dev/null 2>&1; then
      local INSTALL_STRING+=" $PACKAGE"
      let COUNTER++
    fi
  done
  unset PACKAGE

  if [ $COUNTER -gt 0 ]; then

    if ! sudo apt-get update; then
      echo "Could not execute 'sudo apt-get update'"
      return 1
    fi

    if ! sudo apt-get install$INSTALL_STRING -y; then
      echo "installation of$INSTALL_STRING failed"
      return 1
    fi

    return 0

  else
    echo "  MESSAGE:  All needed dependencies are present!"
    echo ""
    return 0
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

compare_current_with_newest_versions() {
  local CURRENT=$1
  local NEWEST=$2

  if [ "$CURRENT" != "$NEWEST" ]; then
    echo "  MESSAGE:  An update to version $NEWEST is available!"
    echo ""
    return 0
  else
    echo "  MESSAGE:  Already up to date with version $NEWEST!"
    return 1
  fi
}

stop_install_message() {
  echo "  MESSAGE:  An update to $LATEST_VERSION is available."
  echo "  MESSAGE:  Please exit $1 at your earliest"
  echo "  MESSAGE:  convience and re-run this script"
}

check_if_running() {
  case $1 in
    # Wasabi Wallet
    "${SCRIPT_AVAILABLE_PACKAGES[9]}")
      if pgrep wassabee; then
        stop_install_message $1
        return 1
      fi
      ;;
    *)
      echo "$1 is not an option available for this function."
      return 1
      ;;
  esac

  return 0
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

  if $TORSOCKS wget $@; then
    return 0
  else
    echo "  MESSAGE:  Something went wrong with the download"

    if [ $TORSOCKS = "torsocks" ]; then
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
  if [ "$DRY_RUN" != "--dry-run" ]; then

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

  fi
}
