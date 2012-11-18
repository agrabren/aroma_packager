#!/bin/bash

function buildKernels() {
  local DEVICE=$1

  mkdir out/$DEVICE/kernels
  mkdir out/$DEVICE/kernels/vanilla
  mkdir out/$DEVICE/kernels/vanilla/modules

  mv out/$DEVICE/boot.img out/$DEVICE/kernels/vanilla
  mv out/$DEVICE/system/lib/modules/* out/$DEVICE/kernels/vanilla/modules
}

