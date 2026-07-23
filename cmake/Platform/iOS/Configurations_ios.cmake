#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


set(_cmake_Platform_iOS_Configurations_ios_cmake ${CMAKE_CURRENT_LIST_DIR})
if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")

    include(${_cmake_Platform_iOS_Configurations_ios_cmake}/../Common/Clang/Configurations_clang.cmake)

    o3de_append_configurations_options(
        DEFINES
            APPLE
            IOS
            MOBILE
            APPLE_BUNDLE
        COMPILATION
            -miphoneos-version-min=${O3DE_IOS_DEPLOYMENT_TARGET}
            -Wno-shorten-64-to-32
            -fno-aligned-allocation
        LINK_NON_STATIC

            -Wl,-dead_strip
            -miphoneos-version-min=${O3DE_IOS_DEPLOYMENT_TARGET}

            -lpthread
    )
    o3de_set(CMAKE_CXX_EXTENSIONS OFF)
else()

    message(FATAL_ERROR "Compiler ${CMAKE_CXX_COMPILER_ID} not supported in ${O3DE_PAL_PLATFORM_NAME}")

endif()

# Signing
o3de_set(CMAKE_XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS --deep)

# Symbol Stripping
o3de_set(CMAKE_XCODE_ATTRIBUTE_DEPLOYMENT_POSTPROCESSING[variant=debug] "NO")
o3de_set(CMAKE_XCODE_ATTRIBUTE_DEPLOYMENT_POSTPROCESSING[variant=profile] "NO")
o3de_set(CMAKE_XCODE_ATTRIBUTE_DEPLOYMENT_POSTPROCESSING[variant=release] "YES")

# Generate scheme files for Xcode
o3de_set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

# Make modules have the dylib extension
o3de_set(CMAKE_SHARED_MODULE_SUFFIX .dylib)
