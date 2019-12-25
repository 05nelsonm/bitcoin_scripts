#!/bin/bash

if ! contains "$SCRIPT_OPTIONS" "--no-tor"; then

  if  command -v tor 1>/dev/null; then
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

fi
