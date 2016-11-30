#!/bin/bash

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# Preparing to build HDF5"
echo "###################################################################"
echo "$(tput sgr0)"

# The results will be stored relative to the location
# where you stored this script, **not** relative to
# the location of the glog git repo.
PREFIX=`pwd`/..
if [ -d "${PREFIX}/platform" ]
then
    rm -rf "${PREFIX}/platform"
fi
mkdir -p "${PREFIX}/platform"

GLOG_MAJ_VERSION=1.10
GLOG_VERSION=${GLOG_MAJ_VERSION}.0-patch1
GLOG_RELEASE_URL=https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${GLOG_MAJ_VERSION}/hdf5-${GLOG_VERSION}/src/hdf5-${GLOG_VERSION}.tar.gz
GLOG_RELEASE_DIRNAME=hdf5-${GLOG_VERSION}

BUILD_MACOSX_X86_64=YES
BUILD_I386_IOSSIM=YES
BUILD_X86_64_IOSSIM=YES
BUILD_IOS_ARMV7=YES
BUILD_IOS_ARMV7S=YES
BUILD_IOS_ARM64=YES

# DEBUG
BUILD_MACOSX_X86_64=NO
# BUILD_I386_IOSSIM=NO
BUILD_X86_64_IOSSIM=NO
BUILD_IOS_ARMV7=NO
BUILD_IOS_ARMV7S=NO
BUILD_IOS_ARM64=NO
# DEBUG

GLOG_SRC_DIR=/tmp/hdf5

DARWIN=darwin13.4.0

XCODEDIR=`xcode-select --print-path`
IOS_SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
MIN_SDK_VERSION=7.1

MACOSX_PLATFORM=${XCODEDIR}/Platforms/MacOSX.platform
MACOSX_SYSROOT=${MACOSX_PLATFORM}/Developer/MacOSX10.9.sdk

IPHONEOS_PLATFORM=`xcrun --sdk iphoneos --show-sdk-platform-path`
IPHONEOS_SYSROOT=`xcrun --sdk iphoneos --show-sdk-path`

IPHONESIMULATOR_PLATFORM=`xcrun --sdk iphonesimulator --show-sdk-platform-path`
IPHONESIMULATOR_SYSROOT=`xcrun --sdk iphonesimulator --show-sdk-path`

# Uncomment if you want to see more information about each invocation
# of clang as the builds proceed.
# CLANG_VERBOSE="--verbose"

CC=clang
CXX=clang

# NOTE: Google Log does not currently build if you specify 'libstdc++'
# instead of `libc++` here.
STDLIB=libc++

CFLAGS=-Wno-implicit-function-declaration

CXXFLAGS="${CLANG_VERBOSE} ${CFLAGS} -std=c++11 -stdlib=${STDLIB}"
CXXFLAGS_OSX="${CLANG_VERBOSE} ${CFLAGS_OSX} -std=c++11 -stdlib=${STDLIB}"

LDFLAGS="-stdlib=${STDLIB}"
LIBS="-lc++ -lc++abi"

echo "PREFIX ..................... ${PREFIX}"
echo "GLOG_MAJ_VERSION ........... ${GLOG_MAJ_VERSIONitem}"
echo "GLOG_VERSION ............... ${GLOG_VERSION}"
echo "GLOG_RELEASE_URL ........... ${GLOG_RELEASE_URL}"
echo "GLOG_RELEASE_DIRNAME ....... ${GLOG_RELEASE_DIRNAME}"
echo "BUILD_MACOSX_X86_64 ........ ${BUILD_MACOSX_X86_64}"
echo "BUILD_I386_IOSSIM .......... ${BUILD_I386_IOSSIM}"
echo "BUILD_X86_64_IOSSIM ........ ${BUILD_X86_64_IOSSIM}"
echo "BUILD_IOS_ARMV7 ............ ${BUILD_IOS_ARMV7}"
echo "BUILD_IOS_ARMV7S ........... ${BUILD_IOS_ARMV7S}"
echo "BUILD_IOS_ARM64 ............ ${BUILD_IOS_ARM64}"
echo "GLOG_SRC_DIR ............... ${GLOG_SRC_DIR}"
echo "DARWIN ..................... ${DARWIN}"
echo "XCODEDIR ................... ${XCODEDIR}"
echo "IOS_SDK_VERSION ............ ${IOS_SDK_VERSION}"
echo "MIN_SDK_VERSION ............ ${MIN_SDK_VERSION}"
echo "MACOSX_PLATFORM ............ ${MACOSX_PLATFORM}"
echo "MACOSX_SYSROOT ............. ${MACOSX_SYSROOT}"
echo "IPHONEOS_PLATFORM .......... ${IPHONEOS_PLATFORM}"
echo "IPHONEOS_SYSROOT ........... ${IPHONEOS_SYSROOT}"
echo "IPHONESIMULATOR_PLATFORM ... ${IPHONESIMULATOR_PLATFORM}"
echo "IPHONESIMULATOR_SYSROOT .... ${IPHONESIMULATOR_SYSROOT}"
echo "CC ......................... ${CC}"
echo "CFLAGS ..................... ${CFLAGS}"
echo "CXX ........................ ${CXX}"
echo "CXXFLAGS ................... ${CXXFLAGS}"
echo "LDFLAGS .................... ${LDFLAGS}"
echo "LIBS ....................... ${LIBS}"

while true; do
    read -p "Proceed with build? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# Fetch Google Logging"
echo "###################################################################"
echo "$(tput sgr0)"

(
    if [ -d ${GLOG_SRC_DIR} ]
    then
        rm -rf ${GLOG_SRC_DIR}
    fi

    cd `dirname ${GLOG_SRC_DIR}`

    if [ -d ${GLOG_RELEASE_DIRNAME} ]
    then
        rm -rf "${GLOG_RELEASE_DIRNAME}"
    fi
    curl --location ${GLOG_RELEASE_URL} --output ${GLOG_RELEASE_DIRNAME}.tar.gz
    tar xvf ${GLOG_RELEASE_DIRNAME}.tar.gz
    mv "${GLOG_RELEASE_DIRNAME}" "${GLOG_SRC_DIR}"
    rm ${GLOG_RELEASE_DIRNAME}.tar.gz

    # Remove the version of Google Test included with the release.
    # We will replace it with version 1.7.0 in a later step.
    if [ -d "${GLOG_SRC_DIR}/gtest" ]
    then
        rm -r "${GLOG_SRC_DIR}/gtest"
    fi
)

# echo "$(tput setaf 2)"
# echo "###################################################################"
# echo "# Fetch Google Test & Prepare the Configure Script"
# echo "#   (note: This section is lifted from autogen.sh)"
# echo "###################################################################"
# echo "$(tput sgr0)"

# (
#     cd ${GLOG_SRC_DIR}

#     # Check that we're being run from the right directory.
#     if test ! -f src/glog/logging.h.in
#     then
#         cat >&2 << __EOF__
# Could not find source code.  Make sure you are running this script from the
# root of the distribution tree.
# __EOF__
#         exit 1
#     fi

#     # Check that gtest is present. Older versions of glog were stored in SVN
#     # and the gtest directory was setup as an SVN external.  Now, glog is
#     # stored in GitHub and the gtest directory is not included. The commands
#     # below will grab the latest version of gtest. Currently that is 1.7.0.
#     if test ! -e gtest
#     then
#         echo "Google Test not present.  Fetching gtest-1.7.0 from the web..."
#         curl --location https://github.com/google/googletest/archive/release-1.7.0.tar.gz --output gtest-1.7.0.tar.gz
#         tar xvf gtest-1.7.0.tar.gz
#         rm gtest-1.7.0.tar.gz
#         mv googletest-release-1.7.0 gtest
#     fi

#     autoreconf -f -i -Wall,no-obsolete
#     rm -rf autom4te.cache config.h.in~
# )

###################################################################
# This section contains the build commands to create the native
# glog library for Mac OS X.
###################################################################

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# x86_64 for Mac OS X"
echo "###################################################################"
echo "$(tput sgr0)"

if [ "${BUILD_MACOSX_X86_64}" == "YES" ]
then
    (
        cd ${GLOG_SRC_DIR}
        ./configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/x86_64-mac "CC=${CC}" "CFLAGS=${CFLAGS} -arch x86_64" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch x86_64" "LDFLAGS=${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
        ARCH=x86_64-mac
        mkdir -p ${PREFIX}/platform/${ARCH}/include
        mkdir -p ${PREFIX}/platform/${ARCH}/lib
        cp -rf hdf5/include ${PREFIX}/platform/${ARCH}/
        cp -rf hdf5/lib ${PREFIX}/platform/${ARCH}/
    )
fi

###################################################################
# This section contains the build commands for each of the 
# architectures that will be included in the universal binaries.
###################################################################

echo "$(tput setaf 2)"
echo "###########################"
echo "# i386 for iPhone Simulator"
echo "###########################"
echo "$(tput sgr0)"

if [ "${BUILD_I386_IOSSIM}" == "YES" ]
then
    (
        cd ${GLOG_SRC_DIR}
        ./configure --build=x86_64-apple-${DARWIN} --host=i386-apple-${DARWIN} --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/i386-sim "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch i386 -isysroot ${IPHONESIMULATOR_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch i386 -isysroot ${IPHONESIMULATOR_SYSROOT}" LDFLAGS="-arch i386 -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
        ARCH=i386-sim
        mkdir -p ${PREFIX}/platform/${ARCH}/include
        mkdir -p ${PREFIX}/platform/${ARCH}/lib
        cp -rf hdf5/include ${PREFIX}/platform/${ARCH}/
        cp -rf hdf5/lib ${PREFIX}/platform/${ARCH}/
    )
fi

echo "$(tput setaf 2)"
echo "#############################"
echo "# x86_64 for iPhone Simulator"
echo "#############################"
echo "$(tput sgr0)"

if [ "${BUILD_X86_64_IOSSIM}" == "YES" ]
then
    (
        cd ${GLOG_SRC_DIR}
        ./configure --build=x86_64-apple-${DARWIN} --host=x86_64-apple-${DARWIN} --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/x86_64-sim "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch x86_64 -isysroot ${IPHONESIMULATOR_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch x86_64 -isysroot ${IPHONESIMULATOR_SYSROOT}" LDFLAGS="-arch x86_64 -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
        ARCH=x86_64-sim
        mkdir -p ${PREFIX}/platform/${ARCH}/include
        mkdir -p ${PREFIX}/platform/${ARCH}/lib
        cp -rf hdf5/include ${PREFIX}/platform/${ARCH}/
        cp -rf hdf5/lib ${PREFIX}/platform/${ARCH}/
    )
fi

echo "$(tput setaf 2)"
echo "##################"
echo "# armv7 for iPhone"
echo "##################"
echo "$(tput sgr0)"

if [ "${BUILD_IOS_ARMV7}" == "YES" ]
then
    (
        cd ${GLOG_SRC_DIR}
        ./configure --build=x86_64-apple-${DARWIN} --host=armv7-apple-${DARWIN} --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/armv7-ios "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch armv7 -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch armv7 -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch armv7 -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
        ARCH=armv7-ios
        mkdir -p ${PREFIX}/platform/${ARCH}/include
        mkdir -p ${PREFIX}/platform/${ARCH}/lib
        cp -rf hdf5/include ${PREFIX}/platform/${ARCH}/
        cp -rf hdf5/lib ${PREFIX}/platform/${ARCH}/
    )
fi

echo "$(tput setaf 2)"
echo "###################"
echo "# armv7s for iPhone"
echo "###################"
echo "$(tput sgr0)"

if [ "${BUILD_IOS_ARMV7S}" == "YES" ]
then
    (
        cd ${GLOG_SRC_DIR}
        ./configure --build=x86_64-apple-${DARWIN} --host=armv7s-apple-${DARWIN} --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/armv7s-ios "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch armv7s -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch armv7s -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch armv7s -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
        ARCH=armv7s-ios
        mkdir -p ${PREFIX}/platform/${ARCH}/include
        mkdir -p ${PREFIX}/platform/${ARCH}/lib
        cp -rf hdf5/include ${PREFIX}/platform/${ARCH}/
        cp -rf hdf5/lib ${PREFIX}/platform/${ARCH}/
    )
fi

echo "$(tput setaf 2)"
echo "##################"
echo "# arm64 for iPhone"
echo "##################"
echo "$(tput sgr0)"

if [ "${BUILD_IOS_ARM64}" == "YES" ]
then
    (
        cd ${GLOG_SRC_DIR}
        ./configure --build=x86_64-apple-${DARWIN} --host=arm --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX}/platform/arm64-ios "CC=${CC}" "CFLAGS=${CFLAGS} -miphoneos-version-min=${MIN_SDK_VERSION} -arch arm64 -isysroot ${IPHONEOS_SYSROOT}" "CXX=${CXX}" "CXXFLAGS=${CXXFLAGS} -arch arm64 -isysroot ${IPHONEOS_SYSROOT}" LDFLAGS="-arch arm64 -miphoneos-version-min=${MIN_SDK_VERSION} ${LDFLAGS}" "LIBS=${LIBS}"
        make
        make install
        ARCH=arm64-ios
        mkdir -p ${PREFIX}/platform/${ARCH}/include
        mkdir -p ${PREFIX}/platform/${ARCH}/lib
        cp -rf hdf5/include ${PREFIX}/platform/${ARCH}/
        cp -rf hdf5/lib ${PREFIX}/platform/${ARCH}/
    )
fi

echo "$(tput setaf 2)"
echo "###################################################################"
echo "# Create Universal Libraries and Finalize the packaging"
echo "###################################################################"
echo "$(tput sgr0)"

(
    cd ${PREFIX}/platform
    ls 
    pwd
    mkdir universal
    lipo x86_64-sim/lib/libhdf5.a i386-sim/lib/libhdf5.a arm64-ios/lib/libhdf5.a armv7s-ios/lib/libhdf5.a armv7-ios/lib/libhdf5.a -create -output universal/libhdf5.a
)

(
    cd ${PREFIX}
    mkdir lib
    cp -r platform/x86_64-mac/lib/* lib
    cp -r platform/universal/* lib
    rm -rf platform
    lipo -info lib/libhdf5.a
)

echo Done!

