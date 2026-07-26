#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#


# Compile-option variables consumed by 3rdParty Find modules (ported from upstream)
set(O3DE_COMPILE_OPTION_ENABLE_EXCEPTIONS PUBLIC -fexceptions)
set(O3DE_COMPILE_OPTION_EXPORT_SYMBOLS PRIVATE -fvisibility=default)
set(O3DE_COMPILE_OPTION_DISABLE_WARNINGS PRIVATE -w)
set(O3DE_COMPILE_OPTION_DISABLE_DEPRECATED_ENUM_ENUM_CONVERSION PRIVATE -Wno-deprecated-enum-enum-conversion -Wno-enum-enum-conversion)
set(O3DE_COMPILE_OPTION_ENABLE_FAST_MATH -ffast-math)
set(O3DE_COMPILE_OPTION_DISABLE_FAST_MATH -fno-fast-math)
set(O3DE_TARGET_COMPILE_OPTION_ENABLE_FAST_MATH PRIVATE ${O3DE_COMPILE_OPTION_ENABLE_FAST_MATH})
set(O3DE_TARGET_COMPILE_OPTION_DISABLE_FAST_MATH PRIVATE ${O3DE_COMPILE_OPTION_DISABLE_FAST_MATH})

set(_cmake_Platform_Common_Clang_Configurations_clang_cmake ${CMAKE_CURRENT_LIST_DIR})
include(${_cmake_Platform_Common_Clang_Configurations_clang_cmake}/../Configurations_common.cmake)

o3de_append_configurations_options(
    DEFINES_PROFILE
        _FORTIFY_SOURCE=2
    DEFINES_RELEASE
        _FORTIFY_SOURCE=2
    COMPILATION
        -fno-exceptions
        -fvisibility=hidden
        -fvisibility-inlines-hidden
        -Wall
        -Werror

        ###################
        # Disabled warnings (please do not disable any others without first consulting sig-build)
        ###################
        -Wno-inconsistent-missing-override # unfortunately there is no warning in MSVC to detect missing overrides,
            # MSVC's static analyzer can, but that is a different run that most developers are not aware of. A pass
            # was done to fix all hits. Leaving this disabled until there is a matching warning in MSVC.

        -Wrange-loop-analysis
        -Wno-unknown-warning-option # used as a way to mark warnings that are MSVC only
        -Wno-parentheses
        -Wno-reorder
        -Wno-switch
        -Wno-undefined-var-template

        ###################
        # Enabled warnings (that are disabled by default)
        ###################

    COMPILATION_DEBUG
        -O0                         # No optimization
        -g                          # debug symbols
        -fno-inline                 # don't inline functions

        -fstack-protector-all       # Enable stack protectors for all functions
        -fstack-check

    COMPILATION_PROFILE
        -O2
        -g                          # debug symbols

        -fstack-protector-all       # Enable stack protectors for all functions
        -fstack-check

    COMPILATION_RELEASE
        -O2
)

if(O3DE_BUILD_WITH_ADDRESS_SANITIZER)
    o3de_append_configurations_options(
        COMPILATION_DEBUG
            -fsanitize=address
            -fno-omit-frame-pointer
        LINK_NON_STATIC_DEBUG
            -shared-libsan
            -fsanitize=address
    )
endif()
include(${_cmake_Platform_Common_Clang_Configurations_clang_cmake}/../TargetIncludeSystemDirectories_supported.cmake)

