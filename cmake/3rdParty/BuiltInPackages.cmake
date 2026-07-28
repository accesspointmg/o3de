#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# this file allows you to specify download and find_package commands for 
# packages which apply to all platforms (usually header-only)
# individual platforms can enumerate packages in for example
# cmake/3rdParty/Platform/Windows/BuiltInPackages_windows.cmake

#include the platform-specific 3rd party packages. 3rdParty packages can be architecture-specific so look for the architecture-specific file first
#if it doesn't exist, fall back to the non-architecture-specific file. One of them should exist for each platform.
set(pal_package_file_name ${O3DE_ENGINE_CMAKE_3RDPARTY_PAL_PATH}/BuiltInPackages_${O3DE_PAL_PLATFORM_WART}${O3DE_ARCHITECTURE_NAME_EXTENSION}.cmake)
if(EXISTS ${pal_package_file_name})
    include(${pal_package_file_name})
else()
    set(pal_package_file_name ${O3DE_ENGINE_CMAKE_3RDPARTY_PAL_PATH}/BuiltInPackages_${O3DE_PAL_PLATFORM_WART}.cmake)
    include(${pal_package_file_name})
endif()

# add the above file to the ALLFILES list, so that they show up in IDEs
o3de_append_cmake_file_to_ALLFILES(${pal_package_file_name})

# temporary compatibility: 
# Some 3p libraries may still refer to zlib as "3rdParty::zlib" instead of
# the correct "3rdParty::ZLIB" (Case difference).  Until those libraries are updated
# we alias the casing here.  This also provides backward compatibility for Gems that use 3rdParty::zlib
# that are not part of the core O3DE repo.

if (NOT O3DE_SCRIPT_ONLY)
    o3de_download_associated_package(ZLIB)
    find_package(ZLIB)
else()
    add_library(3rdParty::ZLIB IMPORTED INTERFACE GLOBAL)
endif()

add_library(3rdParty::zlib ALIAS 3rdParty::ZLIB)
