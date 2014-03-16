# libtomcrypt-ios

This project contains a bash script (build-ios.sh) which compiles
libtomcrypt for iOS. I have also included the libtomcrypt and libtommath
distributions which were current at the time of writing this project.
You should however not blindly trust me and use them! Put on your
tinfoil hat and validate the signatures. As with all cryptographic
software, you should check if there is a more current version available.

## Requirements

-   A Mac with Xcode 5.1. Using other Xcode versions requires editing
    the build script.

-   Optionally, GPG and http://www.libtom.org/files/key.asc

## Instructions

1.  Check for a more current version of libtomcrypt and libtommath.
    Please, file a bug report using this repository’s issue tracker if
    there is a more current version available.

2.  `git clone --depth=1 https://github.com/mologie/libtomcrypt-ios`

3.  If you are not the embedded libtomcrypt or libtomath versions, using
    Xcode 5.1, or not using the iOS 7.1 SDK, edit `build-ios.sh` and
    change the version numbers.

4.  Edit `build-ios-tomcrypt-config.h` according to your requirements.
    **By default, only SHA1, SHA256 and RSA are enabled!** A list of
    configuration options is available in libtomcrypt’s
    `src/headers/tomcrypt_custom.h` and libtomcrypt’s documentation. The
    contents of the configuration file will be inserted into tomcrypt’s
    custom header file during build-time.

5.  `./build-ios.h`

6.  If everything went well, header files and library files can be found
    in the same directory as the build script.


