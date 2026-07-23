#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_Common_GCC_Configurations_gcc_cmake ${CMAKE_CURRENT_LIST_DIR})
include(${_cmake_Platform_Common_GCC_Configurations_gcc_cmake}/../Configurations_common.cmake)

set(O3DE_GCC_BUILD_FOR_GCOV FALSE CACHE BOOL "Flag to enable the build for gcov usage")
if(O3DE_GCC_BUILD_FOR_GCOV)
    set(O3DE_GCC_GCOV_FLAGS "--coverage")
endif()

set(O3DE_GCC_BUILD_FOR_GPROF FALSE CACHE BOOL "Flag to enable the build for gprof usage")
if(O3DE_GCC_BUILD_FOR_GPROF)
    set(O3DE_GCC_GPROF_FLAGS "-pg")
endif()


o3de_append_configurations_options(
    DEFINES_PROFILE
        _FORTIFY_SOURCE=2
    DEFINES_RELEASE
        _FORTIFY_SOURCE=2

    COMPILATION_C
        -fno-exceptions
        -fvisibility=hidden
        -Wall
        -Werror

        -fpie                   # Position-Independent Executables
        -fstack-protector-all   # Enable stack protectors for all functions

        ${O3DE_GCC_GCOV_FLAGS}
        ${O3DE_GCC_GPROF_FLAGS}

    COMPILATION_CXX
        -fno-exceptions
        -fvisibility=hidden
        -fvisibility-inlines-hidden
        -Wall
        -Werror

        -fpie                   # Position-Independent Executables
        -fstack-protector-all   # Enable stack protectors for all functions

        ${O3DE_GCC_GCOV_FLAGS}
        ${O3DE_GCC_GPROF_FLAGS}

        # Disabled warnings
        -Wno-array-bounds
        -Wno-attributes
        -Wno-class-memaccess
        -Wno-delete-non-virtual-dtor
        -Wno-enum-compare
        -Wno-format-overflow
        -Wno-format-truncation
        -Wno-int-in-bool-context
        -Wno-logical-not-parentheses
        -Wno-memset-elt-size
        -Wno-nonnull-compare
        -Wno-parentheses
        -Wno-reorder
        -Wno-restrict
        -Wno-sequence-point
        -Wno-sign-compare
        -Wno-strict-aliasing
        -Wno-stringop-overflow
        -Wno-stringop-truncation
        -Wno-switch
        -Wno-uninitialized
        -Wno-unused-result

    COMPILATION_DEBUG
        -O0 # No optimization
        -g # debug symbols
        -fno-inline # don't inline functions
    COMPILATION_PROFILE
        -O2
        -g # debug symbols
    COMPILATION_RELEASE
        -O2

    LINK_NON_STATIC
        -Wl,-undefined,error
        -fpie
        -Wl,-z,relro,-z,now
        -Wl,-z,noexecstack
    LINK_EXE
        -pie
        -fpie
        -Wl,-z,relro,-z,now
        -Wl,-z,noexecstack

)

include(${_cmake_Platform_Common_GCC_Configurations_gcc_cmake}/../TargetIncludeSystemDirectories_supported.cmake)
