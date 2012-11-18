#!/bin/bash

if [ "$BUILD_NUMBER" == "" ]
then
  BUILD_NUMBER=Kang
fi

VERSION=DisarmedToaster-0.2.9-$BUILD_NUMBER
GOOVERSION=29

# Include routines
source build/utils.sh
source build/autopatcher.sh
source build/extract.sh
source build/buildprop.sh
source build/kernels.sh

# Clean up workspace from previous build, if not already done
echo Cleaning...
CleanAll

# Prepare for build
mkdir out
mkdir tmp

# Fetch pre-builts
pushd apps > /dev/null
./get-prebuilts
popd > /dev/null

# Let's move all the zip files here for now
echo Relocating packages...
for file in `find . -name *.zip | grep -v bootanimation`
do
  cp $file .
done

# Extract the PA system files
echo "Extracting ParanoidAndroid..."
for file in pa_*.zip
do
  DEVICE=`echo $file | sed 's/pa_\([a-zA-Z]\+\).*/\1/g'`
  extractRom $file pa $DEVICE
  rm $file
done

# Extract the AOKP system files
echo "Extracting AOKP..."
for file in aokp_*.zip
do
  DEVICE=`echo $file | sed 's/aokp_\([a-zA-Z]\+\).*/\1/g'`
  extractRom $file aokp $DEVICE
  rm $file
done

# Extract the primary ROM
echo "Extracting CyanogenMod 10..."
for file in *.zip
do
  DEVICE=`echo $file | sed 's/cm-[0-9\-]\+UNOFFICIAL-\([a-zA-Z]\+\).*/\1/g'`

  unzip $file -d out/$DEVICE >/dev/null

  mkdir out/$DEVICE/cm
  for entry in `cat build/cm_blobs.txt`
  do
    if [ -f out/$DEVICE/$entry ]
    then
      mkdir -p `dirname out/$DEVICE/cm/$entry`
      mv out/$DEVICE/$entry out/$DEVICE/cm/$entry
    fi
  done

  updateProp out/$DEVICE/cm/system/build.prop cm

  # Build the pdroid,v6supercharger patch
  AutoPatcher $file cm10 $DEVICE

  # Move the customizable apps
  mkdir out/$DEVICE/apps
  cp apps/* out/$DEVICE/apps
  for entry in `cat build/builtins.txt`
  do
    mv out/$DEVICE/system/app/$entry out/$DEVICE/apps/$entry
  done

  for entry in `cat build/3rdparty.txt`
  do
    mv out/$DEVICE/system/app/$entry out/$DEVICE/apps/$entry
  done

  rm $file

  buildKernels $DEVICE
done

# Create apps list
if [ -f tmp/app_script ]
then
  rm tmp/app_script
fi

let "item = 1"
for entry in `cat build/builtins.txt`
do
  echo "if" >> tmp/app_script
  echo "  file_getprop(\"/tmp/aroma/customize.prop\",\"item.1.$item\") == \"1\"" >> tmp/app_script
  echo "then" >> tmp/app_script
  echo "  package_extract_file(\"apps/$entry\", \"/system/app/$entry\");" >> tmp/app_script
  echo "endif;" >> tmp/app_script
  let item++
done

let "item = 1"
for entry in `cat build/3rdparty.txt`
do
  echo "if" >> tmp/app_script
  echo "  file_getprop(\"/tmp/aroma/customize.prop\",\"item.2.$item\") == \"1\"" >> tmp/app_script
  echo "then" >> tmp/app_script
  echo "  package_extract_file(\"apps/$entry\", \"/system/app/$entry\");" >> tmp/app_script
  echo "endif;" >> tmp/app_script
  let item++
done

# Build the Aroma Installer
echo "Building Aroma Installer..."
for folder in out/*
do
  # Apply overlay
  cp -r overlay/system/* $folder/system

  cp -r base/META-INF $folder
  cp -r langs $folder/META-INF/com/google/android/aroma
  cp -r apps/* $folder/apps

  # Remove extras
  rm $folder/system/app/CMUpdater.apk

  # Generate the supported language list
  pushd $folder/META-INF/com/google/android/aroma/langs > /dev/null
  rename 's/\.lang.txt/.lang/' *.txt
  grep -h 'language.' * | grep -v '#' > select.lang
  popd > /dev/null

  # Compute the number of files in the PA patch
  DEVICE=`echo $folder | cut -b5-`
  FILECOUNT=`find $folder/system -type f | wc -l`
  CM_FILECOUNT=`find $folder/cm -type f | wc -l`
  PA_FILECOUNT=`find $folder/pa -type f | wc -l`
  AOKP_FILECOUNT=`find $folder/aokp -type f | wc -l`

  if [ "$DEVICE" == "shooter" ]
  then
    BOOT_BLOCK=21
    SYSTEM_BLOCK=23
  else
    BOOT_BLOCK=20
    SYSTEM_BLOCK=22
  fi

  sed "s/\$DEVICE/$DEVICE/g" updater-script | sed -e "/\$APPS_LIST/r tmp/app_script" -e "/\$APPS_LIST/d" | sed "s/\$FILECOUNT/$FILECOUNT/g" | sed "s/\$CM_FILECOUNT/$CM_FILECOUNT/g" | sed "s/\$PA_FILECOUNT/$PA_FILECOUNT/g" | sed "s/\$AOKP_FILECOUNT/$AOKP_FILECOUNT/g" | sed "s/\$SYSTEM_BLOCK/\/dev\/block\/mmcblk0p$SYSTEM_BLOCK/g" | sed "s/\$BOOT_BLOCK/\/dev\/block\/mmcblk0p$BOOT_BLOCK/g" > $folder/META-INF/com/google/android/updater-script
  cp aroma-config $folder/META-INF/com/google/android

  FILENAME=$VERSION-$DEVICE

  echo "Compressing $FILENAME..."
  pushd $folder > /dev/null
  zip -r ../../$FILENAME_unsigned.zip * > /dev/null
  popd > /dev/null
  echo "Signing $FILENAME..."
  java -classpath build/testsign.jar testsign $FILENAME_unsigned.zip $FILENAME.zip
  rm $FILENAME_unsigned.zip
done

