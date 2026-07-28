#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

# common files to all platforms
o3de_install_files(
    FILES
        get_python.cmake
        get_python_package_hash.cmake
        readme.md
        requirements.txt
    DESTINATION python
)

# platform specific files (they are PROGRAMS)
include(Platform/${O3DE_PAL_PLATFORM_NAME}/install_files_${O3DE_PAL_PLATFORM_WART}.cmake)
o3de_install_files(
    FILES ${install_files}
    PROGRAMS
    DESTINATION python
)
