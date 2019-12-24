#!/bin/bash

if command -v tor 1>/dev/null; then

  if service tor status | grep "Active: active" 1>/dev/null; then

    if curl --socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT https://check.torproject.org/ \
       | cat | grep -m 1 Congratulations | xargs 1>/dev/null; then

        echo "Tor connection check: SUCCESSFUL"
        echo "Downloads will occur over Tor!"
        echo ""

        TORSOCKS_PKG="torsocks"
        CURL_TOR_FLAG="--socks5 $TOR_IP:$TOR_PORT --socks5-hostname $TOR_IP:$TOR_PORT"
        WGET_TOR_FLAG="torsocks"
    fi

  fi

fi
