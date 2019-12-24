#!/bin/bash

case $1 in

  ## Information obtained from:
  ## https://docs.wasabiwallet.io/using-wasabi/InstallPackage.html#debian-and-ubuntu
  "wasabi-wallet")
    REPO_OWNER="zkSNACKs"
    REPO_NAME="WalletWasabi"

    PGP_FILE_NAME="PGP.txt"
    PGP_KEY_FINGERPRINT="6FB3872B5D42292F59920797856348328949861E"
    PGP_FILE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/master/$PGP_FILE_NAME"

    LATEST_RELEASE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"
    ;;
esac

unset REPO_OWNER REPO_NAME
