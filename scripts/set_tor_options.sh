#!/bin/bash

if  command -v tor 1>/dev/null; then
  echo "  MESSAGE:  Checking for Tor connectivity..."
  echo ""

  if OUT=$(curl --socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT \
           https://check.torproject.org/ | cat | grep -m 1 "Congratulations" \
           | xargs) && echo "$OUT" | grep -qs "Congratulations"; then
    echo ""
    echo "  MESSAGE:  Tor connectivity check: SUCCESSFUL"
    echo "  MESSAGE:  Downloads will occur over Tor!"

    TORSOCKS_PKG="torsocks"
    CURL_TOR_FLAG="--socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT"
    WGET_TOR_FLAG="torsocks"
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

return 0
