#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# This file is included by find_package(org.o3de.project.automatedtesting CONFIG) and will set PACKAGE_VERSION_COMPATIBLE
# to TRUE or FALSE based on whether the requested version is compatible with this project.
# This file also sets PACKAGE_VERSION and PACKAGE_VERSION_EXACT if it can determine
# that information from the project.json.
set(PACKAGE_VERSION_COMPATIBLE FALSE)
set(PACKAGE_VERSION_EXACT FALSE)
get_filename_component(project_path "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
get_property(project_name GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_NAME")
get_property(project_version GLOBAL PROPERTY "O3DE_PATH_${project_path}/project.json_VERSION")
set(PACKAGE_VERSION ${project_version})
if(NOT PACKAGE_FIND_VERSION)
    set(PACKAGE_VERSION_COMPATIBLE TRUE)
    return()
endif()
if(PACKAGE_FIND_VERSION_EXACT)
    # Exact version match required
    if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
        set(PACKAGE_VERSION_EXACT TRUE)
    endif()
else()
    # Compatible version (requested version >= actual version)
    if(PACKAGE_VERSION VERSION_GREATER_EQUAL PACKAGE_FIND_VERSION)
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
        # Check if it's an exact match
        if(PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)
            set(PACKAGE_VERSION_EXACT TRUE)
        endif()
    endif()
endif()
# Debug output
if(PACKAGE_VERSION_COMPATIBLE)
    message(VERBOSE "The project '${project_name}' version '${project_version}' at '${project_path}' is compatible with requested version '${PACKAGE_FIND_VERSION}'")
else()
    message(VERBOSE "The project '${project_name}' version '${project_version}' at '${project_path}' is NOT compatible with requested version '${PACKAGE_FIND_VERSION}'")
endif()
