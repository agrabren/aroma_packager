#!/bin/bash

# This will update the build.prop, but VERSION and GOOVERSION must be set
function updateProp() {
  local FILE=$1
  local TYPE=$2

  if [ -f tmp/prop.tmp ]
  then
    rm tmp/prop.tmp
  fi

  # ParanoidAndroid uses rom.cm.version
  if [ "$TYPE" == "pa" ]
  then
    TYPE=cm
  fi

  # Remove old versions from the build.prop file
  cat $FILE | grep -v "ro\.$TYPE\.version" | grep -v "ro\.goo\." > tmp/prop.tmp
  mv -f tmp/prop.tmp $FILE

  # Handle version field
  echo ro.$TYPE.version=$VERSION>>$FILE

  # Handle GooManager pieces
  echo ro.goo.developerid=agrabren>>$FILE
  echo ro.goo.rom=DisarmedToaster>>$FILE
  echo ro.goo.version=$GOOVERSION>>$FILE
}

