#!/bin/bash

local CURRENT=$1
local NEWEST=$2

if [ "$CURRENT" != "$NEWEST" ]; then
  echo "  MESSAGE:  A New Version is available!"
  echo ""
  return 0
else
  echo "  MESSAGE:  Newest version $NEWEST is already installed"
  return 1
fi
