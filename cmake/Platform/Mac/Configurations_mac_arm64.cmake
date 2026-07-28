#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")

    include(cmake/Platform/Common/Clang/Configurations_clang.cmake)

    o3de_append_configurations_options(
        DEFINES
            APPLE
            MAC
            __APPLE__
            DARWIN

        LINK_NON_STATIC
            -headerpad_max_install_names
            -lpthread
            -lncurses
    )
    o3de_set(CMAKE_CXX_EXTENSIONS OFF)
else()

    message(FATAL_ERROR "Compiler ${CMAKE_CXX_COMPILER_ID} not supported in ${O3DE_PAL_PLATFORM_NAME}")

endif()

# Signing
o3de_set(CMAKE_XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS "--deep")

# Generate scheme files for Xcode
o3de_set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

# Make modules have the dylib extension
o3de_set(CMAKE_SHARED_MODULE_SUFFIX .dylib)
