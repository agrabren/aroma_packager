#!/bin/bash

# Helper Functions
function AutoPatcher() {
  local FILE=$1
  local TYPE=$2
  local DEVICE=$3
  local PATCH=pd2.0,v6supercharger

  # Select the proper patches
  pushd tmp > /dev/null
  ../autopatcher/auto_patcher ../$FILE $PATCH

  if [ -d extract ]
  then
    rm -fr extract
  fi
  mkdir extract

  unzip update.zip -d extract

  mkdir ../out/$DEVICE/"$TYPE"_pdroid
  mkdir ../out/$DEVICE/"$TYPE"_pdroid/system
  cp -r extract/system/* ../out/$DEVICE/"$TYPE"_pdroid/system
  rm -fr extract
  popd > /dev/null

  return 0
}

