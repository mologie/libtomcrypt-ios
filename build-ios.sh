#!/bin/bash

# Basing on https://raw.github.com/st3fan/ios-openssl/master/build.sh - thanks!

set -x
set -e

TOMMATH_VERSION="0.42.0"
TOMCRYPT_VERSION="1.17"

# Setup paths to stuff we need

DEVELOPER="/Applications/Xcode.app/Contents/Developer"

SDK_VERSION="7.1"
MIN_VERSION="4.3"

IPHONEOS_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
IPHONEOS_SDK="${IPHONEOS_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"
IPHONEOS_GCC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

IPHONESIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
IPHONESIMULATOR_SDK="${IPHONESIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"
IPHONESIMULATOR_GCC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

# Make sure things actually exist

if [ ! -d "$IPHONEOS_PLATFORM" ]; then
  echo "Cannot find $IPHONEOS_PLATFORM"
  exit 1
fi

if [ ! -d "$IPHONEOS_SDK" ]; then
  echo "Cannot find $IPHONEOS_SDK"
  exit 1
fi

if [ ! -x "$IPHONEOS_GCC" ]; then
  echo "Cannot find $IPHONEOS_GCC"
  exit 1
fi

if [ ! -d "$IPHONESIMULATOR_PLATFORM" ]; then
  echo "Cannot find $IPHONESIMULATOR_PLATFORM"
  exit 1
fi

if [ ! -d "$IPHONESIMULATOR_SDK" ]; then
  echo "Cannot find $IPHONESIMULATOR_SDK"
  exit 1
fi

if [ ! -x "$IPHONESIMULATOR_GCC" ]; then
  echo "Cannot find $IPHONESIMULATOR_GCC"
  exit 1
fi

# Clean up whatever was left from our previous build

rm -rf include lib
rm -rf /tmp/libtommath-${TOMMATH_VERSION}-*
rm -rf /tmp/libtommath-${TOMMATH_VERSION}-*.*-log
rm -rf /tmp/libtomcrypt-${TOMCRYPT_VERSION}-*
rm -rf /tmp/libtomcrypt-${TOMCRYPT_VERSION}-*.*-log

buildMath()
{
	export ARCH=$1
	export CC="$2 -miphoneos-version-min=${MIN_VERSION}"
	export SDK=$3
	export CFLAGS="-arch ${ARCH} -isysroot ${SDK} -arch ${ARCH} $4"
	export LDFLAGS="-arch ${ARCH}"
	rm -rf "libtommath-${TOMMATH_VERSION}"
	tar xf "ltm-${TOMMATH_VERSION}.tar.bz2"
	pushd .
	cd "libtommath-${TOMMATH_VERSION}"
	make -j5 | tee "/tmp/libtommath-${TOMMATH_VERSION}-${ARCH}.build-log"
	make INSTALL_USER=`id -un` INSTALL_GROUP=`id -gn` "LIBPATH=/tmp/libtommath-${TOMMATH_VERSION}-${ARCH}/lib" "INCPATH=/tmp/libtommath-${TOMMATH_VERSION}-${ARCH}/include" "DATAPATH=/tmp/libtommath-${TOMMATH_VERSION}-${ARCH}/docs" NODOCS=1 install | tee "/tmp/libtommath-${TOMMATH_VERSION}-${ARCH}.install-log"
	popd
	rm -rf "libtommath-${TOMMATH_VERSION}"
}

buildCrypt()
{
	export ARCH=$1
	export CC="$2 -miphoneos-version-min=${MIN_VERSION}"
	export SDK=$3
	export CFLAGS="-arch ${ARCH} -isysroot ${SDK} -I/tmp/libtommath-${TOMMATH_VERSION}-${ARCH}/include $4"
	export LDFLAGS="-arch ${ARCH}"
	rm -rf "libtomcrypt-${TOMCRYPT_VERSION}"
	tar xf "crypt-${TOMCRYPT_VERSION}.tar.bz2"
	pushd .
	cd "libtomcrypt-${TOMCRYPT_VERSION}"
	sed -e '3r ../build-ios-tomcrypt-config.h' -i '' src/headers/tomcrypt_custom.h
	make -j5 library | tee "/tmp/libtomcrypt-${TOMCRYPT_VERSION}-${ARCH}.build-log"
	make INSTALL_USER=`id -un` INSTALL_GROUP=`id -gn` "LIBPATH=/tmp/libtomcrypt-${TOMCRYPT_VERSION}-${ARCH}/lib" "INCPATH=/tmp/libtomcrypt-${TOMCRYPT_VERSION}-${ARCH}/include" "DATAPATH=/tmp/libtomcrypt-${TOMCRYPT_VERSION}-${ARCH}/docs" NODOCS=1 install | tee "/tmp/libtomcrypt-${TOMCRYPT_VERSION}-${ARCH}.install-log"
	popd
	rm -rf "libtomcrypt-${TOMCRYPT_VERSION}"
}

buildMath "armv7" "${IPHONEOS_GCC}" "${IPHONEOS_SDK}" ""
buildMath "armv7s" "${IPHONEOS_GCC}" "${IPHONEOS_SDK}" ""
buildMath "arm64" "${IPHONEOS_GCC}" "${IPHONEOS_SDK}" ""
buildMath "i386" "${IPHONESIMULATOR_GCC}" "${IPHONESIMULATOR_SDK}" ""
buildMath "x86_64" "${IPHONESIMULATOR_GCC}" "${IPHONESIMULATOR_SDK}" ""

buildCrypt "armv7" "${IPHONEOS_GCC}" "${IPHONEOS_SDK}" ""
buildCrypt "armv7s" "${IPHONEOS_GCC}" "${IPHONEOS_SDK}" ""
buildCrypt "arm64" "${IPHONEOS_GCC}" "${IPHONEOS_SDK}" ""
buildCrypt "i386" "${IPHONESIMULATOR_GCC}" "${IPHONESIMULATOR_SDK}" ""
buildCrypt "x86_64" "${IPHONESIMULATOR_GCC}" "${IPHONESIMULATOR_SDK}" ""

# Aggregate library and include files

mkdir include
cp -r /tmp/libtommath-${TOMMATH_VERSION}-i386/include/* include/
cp -r /tmp/libtomcrypt-${TOMCRYPT_VERSION}-i386/include/* include/

mkdir lib
xcrun -sdk iphoneos lipo \
	"/tmp/libtommath-${TOMMATH_VERSION}-armv7/lib/libtommath.a" \
	"/tmp/libtommath-${TOMMATH_VERSION}-armv7s/lib/libtommath.a" \
	"/tmp/libtommath-${TOMMATH_VERSION}-arm64/lib/libtommath.a" \
	"/tmp/libtommath-${TOMMATH_VERSION}-i386/lib/libtommath.a" \
	"/tmp/libtommath-${TOMMATH_VERSION}-x86_64/lib/libtommath.a" \
	-create -output lib/libtommath.a
xcrun -sdk iphoneos ranlib lib/libtommath.a
xcrun -sdk iphoneos lipo \
	"/tmp/libtomcrypt-${TOMCRYPT_VERSION}-armv7/lib/libtomcrypt.a" \
	"/tmp/libtomcrypt-${TOMCRYPT_VERSION}-armv7s/lib/libtomcrypt.a" \
	"/tmp/libtomcrypt-${TOMCRYPT_VERSION}-arm64/lib/libtomcrypt.a" \
	"/tmp/libtomcrypt-${TOMCRYPT_VERSION}-i386/lib/libtomcrypt.a" \
	"/tmp/libtomcrypt-${TOMCRYPT_VERSION}-x86_64/lib/libtomcrypt.a" \
	-create -output lib/libtomcrypt.a
xcrun -sdk iphoneos ranlib lib/libtomcrypt.a

rm -rf "/tmp/libtommath-${TOMMATH_VERSION}-*"
rm -rf "/tmp/libtommath-${TOMMATH_VERSION}-*.*-log"
rm -rf "/tmp/libtomcrypt-${TOMCRYPT_VERSION}-*"
rm -rf "/tmp/libtomcrypt-${TOMCRYPT_VERSION}-*.*-log"
