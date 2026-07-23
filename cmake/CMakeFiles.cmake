#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT INSTALLED_ENGINE)
    # Add all cmake files in a project so they can be handled from within the IDE
    o3de_append_cmake_file_list_to_ALLFILES(${O3DE_ENGINE_CMAKE_PATH}/cmake_files.cmake)
    add_custom_target(CMakeFiles SOURCES ${ALLFILES})
    o3de_source_groups_from_folders("${ALLFILES}")
    unset(ALLFILES)
endif()