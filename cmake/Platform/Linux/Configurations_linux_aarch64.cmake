#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(_cmake_Platform_Linux_Configurations_linux_aarch64_cmake ${CMAKE_CURRENT_LIST_DIR})
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")

    include(${_cmake_Platform_Linux_Configurations_linux_aarch64_cmake}/../Common/Clang/Configurations_clang.cmake)

    o3de_append_configurations_options(
        DEFINES
            LINUX
            __linux__
            LINUX64

        COMPILATION
            -ffp-contract=off

        LINK_NON_STATIC
            -Wl,--no-undefined
            -fpie
            -Wl,-z,relro,-z,now
            -Wl,-z,noexecstack
        LINK_EXE
            -fpie
            -Wl,-z,relro,-z,now
            -Wl,-z,noexecstack
            -Wl,--disable-new-dtags
    )

    o3de_set(CMAKE_CXX_EXTENSIONS OFF)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")

    include(${_cmake_Platform_Linux_Configurations_linux_aarch64_cmake}/../Common/GCC/Configurations_gcc.cmake)

    if(O3DE_GCC_BUILD_FOR_GCOV)
        set(O3DE_GCC_GCOV_LFLAGS "-lgcov")
    endif()
    if(O3DE_GCC_BUILD_FOR_GPROF)
        set(O3DE_GCC_GPROF_LFLAGS "-pg")
    endif()

    o3de_append_configurations_options(
        DEFINES
            LINUX
            __linux__
            LINUX64

        COMPILATION
            -ffp-contract=off

        LINK_NON_STATIC
            ${O3DE_GCC_GCOV_LFLAGS}
            ${O3DE_GCC_GPROF_LFLAGS}
            -Wl,--no-undefined
            -lpthread
            -Wl,--disable-new-dtags
    )
    o3de_set(CMAKE_CXX_EXTENSIONS OFF)

else()
    message(FATAL_ERROR "Compiler ${CMAKE_CXX_COMPILER_ID} not supported in ${O3DE_PAL_PLATFORM_NAME}")
endif()

o3de_set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
o3de_set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
o3de_set(CMAKE_INSTALL_RPATH "$ORIGIN")
