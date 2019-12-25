#!/bin/bash

local CURRENT=$1
local NEWEST=$2

if [ "$CURRENT" != "$NEWEST" ]; then
  echo "A New Version is available!"
  echo ""
else
  echo "Newest version $NEWEST is already installed"
  exit 0
fi
