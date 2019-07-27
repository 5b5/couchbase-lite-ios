#!/bin/sh

#  BuildIPhoneXCFramework.sh
#  CouchbaseLite#

# Version 1.0
# 
# Purpose:
#   Create an XCFramework iPhone from within XCode, supporting iPhone, iPhoneSimulator and UIKitForMac
#
# Based on: BuildFatLibrary.sh by Jens Alfke
#
# More info: see this Stack Overflow question: http://stackoverflow.com/questions/3520977/build-fat-static-library-device-simulator-using-xcode-and-sdk-4

#################[ Tests: helps workaround any future bugs in Xcode ]########
#

BASE_PWD="$PWD"
SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
PROJECT_DIR="${SCRIPT_DIR}/.."
PROJECT="${PROJECT_DIR}/CouchbaseLite.xcodeproj"

export ALREADYINVOKED="true"

ACTION="archive"
CONFIGURATION="Release"
if [ "$1" == "cbl_listener" ]; then
   PRODUCT_NAME="CouchbaseLiteListener"
   TARGET_NAME="CBL Listener iOS XCFramework"
   SCHEME_NAME="CBL Listener iOS XCFramework"
elif [ "$1" == "cbl" ]; then
   PRODUCT_NAME="CouchbaseLite"
   TARGET_NAME="CBL iOS XCFramework"
   SCHEME_NAME="Continuous iOS XCFramework"
else
   "${SCRIPT_DIR}/${SCRIPT_NAME}" cbl
   "${SCRIPT_DIR}/${SCRIPT_NAME}" cbl_listener
   exit 0
fi
EXECUTABLE_NAME="${PRODUCT_NAME}.framework"
BUILD_DIR="${PROJECT_DIR}/build"
PRODUCTS_DIR="${PROJECT_DIR}/products"
XCFRAMEWORK_DIR=${BUILD_DIR}/${CONFIGURATION}-iOS-universal
XCFRAMEWORK_NAME="${XCFRAMEWORK_DIR}/${EXECUTABLE_NAME/.framework/.xcframework}"
XCFRAMEWORK_COMMAND="xcodebuild -create-xcframework -output \"${XCFRAMEWORK_NAME}\" "

rm -Rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${PRODUCTS_DIR}"
mkdir -p "${XCFRAMEWORK_DIR}"

function combineLibs {
   # Combined all static libaries in the current directory into a single static library
   # It is hardcoded to use the i386, armv7, and armv7s architectures; this can easily be changed via the 'archs' variable at the top
   # The script takes a single argument, which is the name of the final, combined library to be created.
   #
   #   For example:
   #  =>    combine_static_libraries.sh combined-library
   #
   # Script by Evan Schoenberg, Regular Rate and Rhythm Software
   # Thanks to Claudiu Ursache for his blog post at http://www.cvursache.com/2013/10/06/Combining-Multi-Arch-Binaries/ which detailed the technique automated by this script
   #####
   # $1 = Name of output archive
   #####
   local PATTERN="$1"
   local OUTPUT_NAME="$2"
   local DIR="$3"
   
   archs=(i386 x86_64 armv7 armv7s arm64)
   echo "combineLibs called for $1 in $2"
   cd "${DIR}"
   libraries=(*"$PATTERN"*.a)
   libtool="/usr/bin/libtool"

   echo "Combining ${libraries[*]}..."

   for library in ${libraries[*]}
   do
       lipo -info $library
       local archs=$( lipo -archs $library )
    
       # Extract individual architectures for this library
       for arch in ${archs[*]}
       do
          if lipo -info "$library" | grep "Non-fat"; then
             cp "$library" "${library}_${arch}.a"
          else
             lipo -thin $arch $library -o ${library}_${arch}.a
          fi
       done
   done

   # Combine results of the same architecture into a library for that architecture
   source_combined=""
   for arch in ${archs[*]}
   do
       source_libraries=""
    
       for library in ${libraries[*]}
       do
         if [ -f "${library}_${arch}.a" ]; then
              source_libraries="${source_libraries} ${library}_${arch}.a"
         fi
       done
    
       if [ "$source_libraries" != "" ]; then
          $libtool -static ${source_libraries} -o "${OUTPUT_NAME}_${arch}.a"
          source_combined="${source_combined} ${OUTPUT_NAME}_${arch}.a"
    
          # Delete intermediate files
          rm ${source_libraries}
       fi
   done

   # Merge the combined library for each architecture into a single fat binary
   lipo -create $source_combined -o ${OUTPUT_NAME}

   # Delete intermediate files
   rm ${source_combined}

   # Show info on the output library as confirmation
   echo "Combination complete."
   lipo -info ${OUTPUT_NAME}
}

function build {
   local TYPE="$1"
   local CONFIGURATION_BUILD_DIR="${BUILD_DIR}/${CONFIGURATION}-${TYPE}"
   local SDK_NAME=""
   local DSTROOT="/tmp/${PRODUCT_NAME}-${TYPE}.dst"
   
   if [ "$TYPE" == "uikitformac" ]; then
      ACTION="build"
      echo "About to invoke: xcodebuild -configuration \"${CONFIGURATION}\" -scheme \"${SCHEME_NAME}\" -destination=\"platform=macOS\" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO"
      xcodebuild -project "${PROJECT}" -configuration "${CONFIGURATION}" -scheme "${SCHEME_NAME}" -destination="platform=macOS" -archivePath="${CONFIGURATION_BUILD_DIR}/${EXECUTABLE_NAME}" ${ACTION} DSTROOT="${DSTROOT}" RUN_CLANG_STATIC_ANALYZER=NO ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR}" BUILD_DIR="${BUILD_DIR}" CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}" CBL_VERSION_STRING="${CBL_VERSION_STRING}" CBL_SOURCE_REVISION="${CBL_SOURCE_REVISION}" || exit 1
   else
      ACTION="archive"
      SDK_NAME="${TYPE}"
      echo "About to invoke: xcodebuild -configuration \"${CONFIGURATION}\" -target \"${TARGET_NAME}\" -sdk \"${SDK_NAME}\" ${ACTION} RUN_CLANG_STATIC_ANALYZER=NO"
      xcodebuild -project "${PROJECT}" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" -sdk "${SDK_NAME}" -archivePath="${CONFIGURATION_BUILD_DIR}/${EXECUTABLE_NAME}" ${ACTION} DSTROOT="${DSTROOT}" RUN_CLANG_STATIC_ANALYZER=NO ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= CONFIGURATION_BUILD_DIR="${CONFIGURATION_BUILD_DIR}" BUILD_DIR="${BUILD_DIR}" CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}" CBL_VERSION_STRING="${CBL_VERSION_STRING}" CBL_SOURCE_REVISION="${CBL_SOURCE_REVISION}" || exit 1
   fi
   local FRAMEWORK_DIR="${CONFIGURATION_BUILD_DIR}/${EXECUTABLE_NAME}"
   if [ -d "${FRAMEWORK_DIR}/Contents" ]; then
      # XCode generated a MAC-Style Framework...
      cp -Rf "${FRAMEWORK_DIR}/Contents/"* "${FRAMEWORK_DIR}"
      rm -Rf "${FRAMEWORK_DIR}/Contents"
      cp -Rf "${FRAMEWORK_DIR}/MacOS/"* "${FRAMEWORK_DIR}"
      rm -Rf "${FRAMEWORK_DIR}/MacOS"
   fi
   mv -f "${CONFIGURATION_BUILD_DIR}/lib${PRODUCT_NAME}.a" "${FRAMEWORK_DIR}/${PRODUCT_NAME}"
   if [ -d "${CONFIGURATION_BUILD_DIR}/usr/local/include" ]; then
      mkdir -p "${FRAMEWORK_DIR}/usr/local/include"
      cp "${CONFIGURATION_BUILD_DIR}/usr/local/include/"* "${FRAMEWORK_DIR}/usr/local/include"
   fi
   
   XCFRAMEWORK_COMMAND="${XCFRAMEWORK_COMMAND} -framework \"${FRAMEWORK_DIR}\""
}


build iphoneos
build iphonesimulator
build uikitformac

rm -Rf "${PRODUCTS_DIR}/${EXECUTABLE_NAME/.framework/.xcframework}"
echo "About to invoke: ${XCFRAMEWORK_COMMAND}"
eval ${XCFRAMEWORK_COMMAND}

cp -RL "${XCFRAMEWORK_NAME}" "${PRODUCTS_DIR}"
