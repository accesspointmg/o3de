#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# to use this script, invoke it using CMake script mode (-P option) 
# with the cwd being the engine root folder (the one with cmake as a subfolder)
# on the command line, define O3DE_3RDPARTY_PATH to a valid directory
# and O3DE_PAL_PLATFORM_NAME to the platform you'd like to get or update python for.
# defines must come before the script call.
# example:
# cmake -DPAL_PLATFORM_NAME:string=Windows -DLY_3RDPARTY_PATH:string=%CMD_DIR% -P get_python.cmake

cmake_minimum_required(VERSION 3.24)

if(O3DE_3RDPARTY_PATH)
    file(TO_CMAKE_PATH ${O3DE_3RDPARTY_PATH} O3DE_3RDPARTY_PATH)
    cmake_path(NORMAL_PATH O3DE_3RDPARTY_PATH)
endif()

if (O3DE_ENGINE_PATH)
    file(TO_CMAKE_PATH ${O3DE_ENGINE_PATH} O3DE_ENGINE_PATH)
    cmake_path(NORMAL_PATH O3DE_ENGINE_PATH)
endif()

set(O3DE_PAL_HOST_PLATFORM_NAME ${O3DE_PAL_PLATFORM_NAME})
string(TOLOWER ${O3DE_PAL_HOST_PLATFORM_NAME} O3DE_PAL_HOST_PLATFORM_NAME_LOWERCASE)

string(TOLOWER ${O3DE_PAL_PLATFORM_NAME} O3DE_PAL_PLATFORM_WART)

include(cmake/O3dePython.cmake)
