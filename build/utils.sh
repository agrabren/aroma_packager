#!/bin/bash

# Clean All
function CleanAll() {
  echo Cleaning install area...
  rm *.zip
  if [ -d out ]
  then
    rm -fr out
  fi
  if [ -d tmp ]
  then
    rm -fr tmp
  fi
}

