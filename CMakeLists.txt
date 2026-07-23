#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

cmake_minimum_required(VERSION 3.22)

if(NOT ${CMAKE_VERSION} VERSION_LESS "3.24") 
    # CMP0135 - controls whether, when unpacking an archive file, it should:
    # (OLD) set the file timestamps to what they are in the archive (not recommended)
    # (NEW) set the file timestamps to the time of extraction (recommended)
    cmake_policy(SET CMP0135 NEW) 
endif()

if(NOT PROJECT_NAME)
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")

    # include the engine cmake
    include(cmake/Engine.cmake)

    # init the engine
    o3de_engine_init()

    # Set the cmake project from this o3de engine object
    project(${engine_name}
        LANGUAGES C CXX
        VERSION ${engine_version}
        DESCRIPTION ${engine_description}
    )

    # Setup
    o3de_engine_setup()

    set(O3DE_ENGINE_IS_TOPLEVEL TRUE)
endif()

# Add all the subdirectories for this engine.
# This runs both engine-centric (top-level) and project-centric (the
# project bootstrap add_subdirectory()s the engine after its own setup,
# which already performed the equivalent init/setup).
get_property(o3de_engine_subdirs_added GLOBAL PROPERTY O3DE_ENGINE_SUBDIRS_ADDED)
if(NOT o3de_engine_subdirs_added)
    set_property(GLOBAL PROPERTY O3DE_ENGINE_SUBDIRS_ADDED TRUE)
    # Composed workspaces may omit some engine subtrees (e.g. Templates
    # are composed at workspace level) — add what exists
    foreach(engine_subdir Assets Code python Registry scripts Templates Tools)
        if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${engine_subdir}/CMakeLists.txt)
            add_subdirectory(${engine_subdir})
        endif()
    endforeach()
endif()

if(O3DE_ENGINE_IS_TOPLEVEL)
    # Call the post processing macro
    o3de_engine_post_processing()
endif()
