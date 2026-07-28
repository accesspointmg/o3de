#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.24)

if(NOT ${CMAKE_VERSION} VERSION_LESS "3.24") 
    # CMP0135 - controls whether, when unpacking an archive file, it should:
    # (OLD) set the file timestamps to what they are in the archive (not recommended)
    # (NEW) set the file timestamps to the time of extraction (recommended)
    cmake_policy(SET CMP0135 NEW) 
endif()

if(NOT PROJECT_NAME)
    # Locate the engine that provides Project.cmake.
    # 1. Explicit -DO3DE_ENGINE_PATH=<path> (used by workspace builds where
    #    the engine is composed at <workspace>/Engines/<name>)
    # 2. Sibling engine layout (project lives inside the engine source tree)
    if(NOT O3DE_ENGINE_PATH)
        cmake_path(SET O3DE_ENGINE_PATH NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}/..")
    endif()
    if(NOT EXISTS "${O3DE_ENGINE_PATH}/cmake/Project.cmake")
        message(FATAL_ERROR
            "Could not find an engine at '${O3DE_ENGINE_PATH}'. "
            "Pass -DO3DE_ENGINE_PATH=<engine root> or place this project "
            "inside an engine source tree.")
    endif()
    list(APPEND CMAKE_MODULE_PATH "${O3DE_ENGINE_PATH}/cmake")

    # Include the project cmake
    include(${O3DE_ENGINE_PATH}/cmake/Project.cmake)
    
    # Init the project
    o3de_project_init()

   # Set the cmake project from this o3de project object
    project(${project_name}
        LANGUAGES C CXX
        VERSION ${project_version}
        DESCRIPTION ${project_description}
    )

    # Setup
    o3de_project_setup()

    # Add the project's embedded gem.  In composed workspaces the gem is
    # flattened to workspace level and added by the manifest traversal.
    if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/Gem/CMakeLists.txt)
        add_subdirectory(Gem)
    endif()

    # call the post processing macro
    o3de_project_post_processing()
endif()
