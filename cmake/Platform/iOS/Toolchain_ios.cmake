#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


set(_cmake_Platform_iOS_Toolchain_ios_cmake ${CMAKE_CURRENT_LIST_DIR})
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_OSX_ARCHITECTURES arm64)


set(O3DE_IOS_CODE_SIGNING_IDENTITY "iPhone Developer" CACHE STRING "iPhone Developer")
set(O3DE_IOS_DEPLOYMENT_TARGET "14.0" CACHE STRING "iOS Deployment Target")
set(O3DE_IOS_DEVELOPMENT_TEAM "CF9TGN983S" CACHE STRING "The development team ID")


# PAL variables
set(O3DE_PAL_PLATFORM_NAME iOS)


include(${_cmake_Platform_iOS_Toolchain_ios_cmake}/SDK_ios.cmake)

set(CMAKE_XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${O3DE_IOS_DEPLOYMENT_TARGET})
set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")

set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE NO)

set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED YES)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ${O3DE_IOS_CODE_SIGNING_IDENTITY})
set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${O3DE_IOS_DEVELOPMENT_TEAM})
