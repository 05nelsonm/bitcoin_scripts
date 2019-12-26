#!/bin/bash

local CURRENT=$1
local NEWEST=$2

if [ "$CURRENT" != "$NEWEST" ]; then
  echo "  MESSAGE:  A New Version is available!"
  echo ""
  return 0
else
  echo "  MESSAGE:  Already up to date with version $NEWEST"
  return 1
fi
