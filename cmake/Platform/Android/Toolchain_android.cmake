#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(O3DE_TOOLCHAIN_NDK_API_LEVEL)
  return()
endif()

# Verify that the NDK environment is set and points to the support NDK
if(NOT O3DE_NDK_DIR)
    if(DEFINED ENV{O3DE_NDK_DIR})
        set(O3DE_NDK_DIR $ENV{O3DE_NDK_DIR})
    endif()
endif()
file(TO_CMAKE_PATH "${O3DE_NDK_DIR}" O3DE_NDK_DIR)
if(NOT O3DE_NDK_DIR)
    message(FATAL_ERROR "Environment and cache var for NDK is empty. Could not find the NDK installation folder")
endif()

set(O3DE_ANDROID_NDK_TOOLCHAIN ${O3DE_NDK_DIR}/build/cmake/android.toolchain.cmake)
if(NOT O3DE_NDK_DIR)
    message(FATAL_ERROR "Invalid NDK Environment. Unable to locate android toolchain file: " ${O3DE_NDK_DIR})
endif()


# Set some default variables that are used by the NDK's toolchain file before processing
if(NOT ANDROID_ABI)
    set(ANDROID_ABI arm64-v8a)
endif()

# Only the 64-bit ANDROID ABIs arm supported
if(NOT ANDROID_ABI MATCHES "^arm64-")
    message(FATAL_ERROR "Only the 64-bit ANDROID_ABI's are supported. arm64-v8a can be used if not set")
endif()

set(MIN_NATIVE_API_LEVEL 24)

if(NOT ANDROID_NATIVE_API_LEVEL)
    set(ANDROID_NATIVE_API_LEVEL ${MIN_NATIVE_API_LEVEL})
endif()

if(${ANDROID_NATIVE_API_LEVEL} VERSION_LESS ${MIN_NATIVE_API_LEVEL})
    message(FATAL_ERROR "Unsupported Android native API version ${ANDROID_NATIVE_API_LEVEL}. Must be ${MIN_NATIVE_API_LEVEL} or above")
endif()

set(ANDROID_PLATFORM android-${ANDROID_NATIVE_API_LEVEL})

# Make a backup of the CMAKE_FIND_ROOT_PATH since it will be altered by the NDK toolchain file and needs to be restored after the input
set(BACKUP_CMAKE_FIND_ROOT_PATH ${CMAKE_FIND_ROOT_PATH})

include(${O3DE_ANDROID_NDK_TOOLCHAIN})

set(CMAKE_FIND_ROOT_PATH ${BACKUP_CMAKE_FIND_ROOT_PATH})

# The CMake Android-Initialize.cmake(https://gitlab.kitware.com/cmake/cmake/-/blob/v3.21.2/Modules/Platform/Android-Initialize.cmake#L61)
# script sets CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH to OFF resulting in find_program calls being unable to locate host binaries
# https://gitlab.kitware.com/cmake/cmake/-/issues/22634
# Setting back to true to fix our find_program calls
set(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH ON)

# Force the ANDROID_LINKER_FLAGS that are set in the NDK's toolchain file into the LINKER_FLAGS for the build and reset
# the standard libraries
set(LINKER_FLAGS ${ANDROID_LINKER_FLAGS})
set(CMAKE_CXX_STANDARD_LIBRARIES "")

# We need to pass down the Android API Level, and the Package Revision's Major and Minor number as preprocessor values.
# We will extract them from 'ANDROID_NDK_SOURCE_PROPERTIES' which will read from the NDK's properties file.
# (note: we cannot use 'ANDROID_NDK_REVISION' because the toolchain combines the Major and Minor revisions
string(REGEX MATCHALL "Pkg.Revision = (([0-9]+).([0-9]+).[0-9]+)" O3DE_NDK_PKG_REVISION_LINE ${ANDROID_NDK_SOURCE_PROPERTIES})
set(O3DE_TOOLCHAIN_NDK_PKG_MAJOR ${CMAKE_MATCH_2})
set(O3DE_TOOLCHAIN_NDK_PKG_MINOR ${CMAKE_MATCH_3})
set(O3DE_TOOLCHAIN_NDK_API_LEVEL ${ANDROID_PLATFORM_LEVEL})

set(MIN_NDK_VERSION 21)

if(${O3DE_TOOLCHAIN_NDK_PKG_MAJOR} VERSION_LESS ${MIN_NDK_VERSION})
    message(FATAL_ERROR "Unsupported NDK Version ${O3DE_TOOLCHAIN_NDK_PKG_MAJOR}.${O3DE_TOOLCHAIN_NDK_PKG_MINOR}. Must be version ${MIN_NDK_VERSION} or above")
else()
    message(STATUS "Detected NDK Version ${O3DE_TOOLCHAIN_NDK_PKG_MAJOR}.${O3DE_TOOLCHAIN_NDK_PKG_MINOR}")
endif()

list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES O3DE_NDK_DIR)


# The Native Activity Glue source file needs to be included in any project that will be loaded
# through the android launcher APK. This source file resides directly in the NDK source folder structure
# based on the configured NDK Path set with ${O3DE_NDK_DIR}


# Locate and verify the source folder based on the NDK path
set(O3DE_NDK_NATIVE_APP_GLUE_SRC_DIR "${O3DE_NDK_DIR}/sources/android/native_app_glue")
file(TO_CMAKE_PATH ${O3DE_NDK_NATIVE_APP_GLUE_SRC_DIR} O3DE_NDK_NATIVE_APP_GLUE_SRC_DIR)
if(NOT IS_DIRECTORY "${O3DE_NDK_NATIVE_APP_GLUE_SRC_DIR}")
    message(FATAL_ERROR "Could not find android native app glue directory: ${O3DE_NDK_NATIVE_APP_GLUE_SRC_DIR}")
endif()
