#!/bin/bash

if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
  echo "Version $LATEST_VERSION is already installed"
  exit 0
fi
