#!/bin/bash

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
  echo "A New Version is available!"
  echo ""
else
  echo "Newest version v$LATEST_VERSION is already installed"
  exit 0
fi
