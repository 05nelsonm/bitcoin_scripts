#!/bin/bash

case $1 in

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
    LATEST_VERSION=$(curl -s $CURL_TOR_FLAG $LATEST_RELEASE_URL | jq -r '.tag_name' | cut -d 'v' -f 2)

    PACKAGE_NAME="Wasabi-$LATEST_VERSION.deb"
    PACKAGE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$LATEST_VERSION/$PACKAGE_NAME"

    SIGNATURE_NAME="$PACKAGE_NAME.asc"
    SIGNATURE_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/v$LATEST_VERSION/$SIGNATURE_NAME"
    ;;
esac
