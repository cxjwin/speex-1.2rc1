#!/bin/sh

#  opencore_amr.sh
#  
#
#  Created by cxjwin on 13-10-17.
#

set -xe

DEVELOPER=`xcode-select -print-path`
OGG=${HOME}/Desktop/speexLibrary/libogg-1.3.0
DEST=${HOME}/Desktop/speexLibrary/speex-1.2rc1

ARCHS="i386 x86_64 armv7 armv7s arm64"
LIBS="libspeex.a libspeexdsp.a"

for arch in $ARCHS;
do
    mkdir -p $DEST/$arch
done

./configure

for arch in $ARCHS;
do  
    make clean
    IOSMV="-miphoneos-version-min=4.3"
    case $arch in
    arm*)  
        echo "Building opencore-amr for iPhoneOS $arch ****************"
        if [ $arch == "arm64" ]
        then
            IOSMV="-miphoneos-version-min=7.0"
        fi
        PATH=`xcodebuild -version -sdk iphoneos PlatformPath`"/Developer/usr/bin:$PATH" \
        SDK=`xcodebuild -version -sdk iphoneos Path` \
        CC="xcrun --sdk iphoneos clang -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include" \
        CXX="xcrun --sdk iphoneos clang++ -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include" \
        LDFLAGS="-Wl,-syslibroot,$SDK" \
        ./configure \
        --host=arm-apple-darwin \
        --prefix=$DEST/$arch \
        --with-ogg=${OGG}/$arch
        ;;
    *)
        echo "Building opencore-amr for iPhoneSimulator $arch *****************"
        PATH=`xcodebuild -version -sdk iphonesimulator PlatformPath`"/Developer/usr/bin:$PATH" \
        CC="xcrun --sdk iphonesimulator clang -arch $arch $IOSMV" \
        CXX="xcrun --sdk iphonesimulator clang++ -arch $arch $IOSMV" \
        ./configure \
        --prefix=$DEST/$arch \
        --with-ogg=${OGG}/$arch
        ;;
    esac
    make -j5
    make install
done

make clean

echo "Merge into universal binary."

for i in $LIBS; 
do
    input=""
    for arch in $ARCHS; 
    do
        input="$input $DEST/$arch/lib/$i"
    done
    lipo -create $input -output $DEST/$i 
done 