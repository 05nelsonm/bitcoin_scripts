#!/bin/bash

local CURRENT=$1
local NEWEST=$2

if [ "$CURRENT" != "$NEWEST" ]; then
  echo "A New Version is available!"
  echo ""
  return 0
else
  echo "Newest version $NEWEST is already installed"
  return 1
fi
