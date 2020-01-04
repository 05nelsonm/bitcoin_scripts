#!/bin/bash

latest_version_error_message() {
  echo "  MESSAGE:  Could not obtain the latest version number"
  echo "  MESSAGE:  from:  $1"
  echo "  MESSAGE:"
  echo "  MESSAGE:  If you're using Tor, try 'sudo service tor restart'"
  echo "  MESSAGE:  and re-run the script"
}

unset PGP_KEY_FINGERPRINT PGP_IMPORT_URL CURRENT_VERSION \
      LATEST_VERSION PACKAGE_NAME PACKAGE_URL \
      SIGNATURE_FILE_NAME SIGNATURE_FILE_URL PGP_FILE_NAME \
      PGP_FILE_URL

case $1 in

  ## Information obtained from:
  ## https://coldcardwallet.com/docs/upgrade
  ## https://github.com/Coldcard/firmware
  "ckcc-firmware")
    local REPO_OWNER="Coldcard"
    local REPO_NAME="firmware"

    PGP_KEY_FINGERPRINT="4589779ADFC14F3327534EA8A3A31BAD5A2A5B10"
    PGP_IMPORT_URL="https://pgp.key-server.io/download/0xA3A31BAD5A2A5B10"

    local LATEST_RELEASE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/tags"

    #CURRENT_VERSION= handled in get_latest.sh

    if ! LATEST_VERSION=$(curl -s $CURL_TOR_FLAG $LATEST_RELEASE_URL | jq '.[6]' | jq -r '.name'); then
      latest_version_error_message $LATEST_RELEASE_URL
      return 1
    fi

    PACKAGE_NAME="$LATEST_VERSION-coldcard.dfu"
    PACKAGE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/raw/master/releases/$PACKAGE_NAME"

    SIGNATURE_FILE_NAME="signatures.txt"
    SIGNATURE_FILE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/raw/master/releases/$SIGNATURE_FILE_NAME"
    ;;

  ## Information obtained from:
  ## https://github.com/Coldcard/ckcc-protocol
  "ckcc-protocol")
    local REPO_OWNER="Coldcard"
    local REPO_NAME="ckcc-protocol"

    #PGP_KEY_FINGERPRINT=
    #PGP_IMPORT_URL=

    local LATEST_RELEASE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/tags"

    if ! LATEST_RELEASE_JSON=$(curl -s $CURL_TOR_FLAG $LATEST_RELEASE_URL | jq '.[0]'); then
      latest_version_error_message $LATEST_RELEASE_URL
      return 1
    fi

    #CURRENT_VERSION= handled in get_latest.sh
    LATEST_VERSION=$(echo "$LATEST_RELEASE_JSON" | jq -r '.name' | cut -d 'v' -f 2)

    PACKAGE_NAME="v$LATEST_VERSION"
    PACKAGE_URL=$(echo "$LATEST_RELEASE_JSON" | jq -r '.tarball_url')

    unset LATEST_RELEASE_JSON
    #SIGNATURE_FILE_NAME=
    #SIGNATURE_FILE_URL=
    ;;

  ## Information obtained from:
  ## https://docs.wasabiwallet.io/using-wasabi/InstallPackage.html#debian-and-ubuntu
  ## https://github.com/zkSNACKs/WalletWasabi
  "wasabi-wallet")
    local REPO_OWNER="zkSNACKs"
    local REPO_NAME="WalletWasabi"

    PGP_KEY_FINGERPRINT="6FB3872B5D42292F59920797856348328949861E"
    PGP_FILE_NAME="PGP.txt"
    PGP_FILE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/master/$PGP_FILE_NAME"

    local LATEST_RELEASE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

    CURRENT_VERSION=$(wassabee -v | grep "Wasabi Client Version:" | cut -d ':' -f 2 | cut -d ' ' -f 2)

    if ! LATEST_VERSION=$(curl -s $CURL_TOR_FLAG $LATEST_RELEASE_URL | jq -r '.tag_name' | cut -d 'v' -f 2); then
      latest_version_error_message $LATEST_RELEASE_URL
      return 1
    fi

    PACKAGE_NAME="Wasabi-$LATEST_VERSION.deb"
    PACKAGE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$LATEST_VERSION/$PACKAGE_NAME"

    SIGNATURE_FILE_NAME="$PACKAGE_NAME.asc"
    SIGNATURE_FILE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$LATEST_VERSION/$SIGNATURE_FILE_NAME"
    ;;
esac

return 0
