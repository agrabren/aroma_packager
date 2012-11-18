#!/bin/bash

# Clean All
function extractRom() {
  local FILE=$1
  local TYPE=$2
  local DEVICE=$3

  if [ ! -d out/$DEVICE ]
  then
    mkdir out/$DEVICE
  fi
  if [ ! -d out/$DEVICE/$TYPE ]
  then
    mkdir out/$DEVICE/$TYPE
  fi

  for entry in `cat build/"$TYPE"_blobs.txt`
  do
    if [ -f $FILE ]
    then
      unzip $FILE -d out/$DEVICE/$TYPE $entry >/dev/null
    fi
  done

  # Fixup the build.prop file
  updateProp out/$DEVICE/$TYPE/system/build.prop $TYPE

  # Build the patch before we delete the file
  AutoPatcher $FILE $TYPE $DEVICE
}

