#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(O3DE_INSTALL_ENABLED TRUE CACHE BOOL "Indicates if the install process is enabled")

#! o3de_install: wrapper to install that handles common functionality
#
# \notes: 
#  - this wrapper handles the case where common installs are called multiple times from different
#      build folders (when using O3DE_INSTALL_EXTERNAL_BUILD_DIRS) to generate install layouts that
#      have multiple build permutations
#
function(o3de_install)

    if(NOT O3DE_INSTALL_ENABLED)
        return()
    endif()

    cmake_parse_arguments(o3de_install "" "COMPONENT" "" ${ARGN})
    if (NOT o3de_install_COMPONENT OR "${o3de_install_COMPONENT}" STREQUAL "${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME}")
        # if it is installing under the default component, we need to de-duplicate since we can have
        # cases coming from different build directories (when using O3DE_INSTALL_EXTERNAL_BUILD_DIRS)
        install(CODE "if(NOT O3DE_CORE_COMPONENT_ALREADY_INCLUDED)" ALL_COMPONENTS)
        install(${ARGN})
        install(CODE "endif()\n" ALL_COMPONENTS)
    else()
        install(${ARGN})
    endif()

endfunction()

#! o3de_install_directory: specifies a directory to be copied to the install layout at install time
#
# \arg:DIRECTORIES directories to install
# \arg:DESTINATION (optional) destination to install the directory to (relative to CMAKE_PREFIX_PATH)
# \arg:EXCLUDE_PATTERNS (optional) patterns to exclude
# \arg:COMPONENT (optional) component to use (defaults to CMAKE_INSTALL_DEFAULT_COMPONENT_NAME)
# \arg:VERBATIM (optional) copies the directories as they are, this excludes the default exclude patterns
#
# \notes: 
#  - refer to cmake's install(DIRECTORY documentation for more information
#  - If the directory contains programs/scripts, exclude them from this call and add a specific o3de_install_files with 
#      PROGRAMS set. This is necessary to set the proper execution permissions.
#  - This function will automatically filter out __pycache__, *.egg-info, CMakeLists.txt, *.cmake files. If those files
#      need to be installed, use o3de_install_files. Use VERBATIM to exclude such filters.
#
function(o3de_install_directory)

    if(NOT O3DE_INSTALL_ENABLED)
        return()
    endif()

    set(options VERBATIM)
    set(oneValueArgs DESTINATION COMPONENT)
    set(multiValueArgs DIRECTORIES EXCLUDE_PATTERNS)

    cmake_parse_arguments(o3de_install_directory "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT o3de_install_directory_DIRECTORIES)
        message(FATAL_ERROR "You must provide at least a directory to install")
    endif()
    
    if(NOT o3de_install_directory_COMPONENT)
        set(o3de_install_directory_COMPONENT ${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME})
    endif()

    foreach(directory ${o3de_install_directory_DIRECTORIES})

        cmake_path(ABSOLUTE_PATH directory)

        if(NOT o3de_install_directory_DESTINATION)
            # maintain the same structure relative to O3DE_ENGINE_PATH
            set(o3de_install_directory_DESTINATION ${directory})
            if(${o3de_install_directory_DESTINATION} STREQUAL ".")
                set(o3de_install_directory_DESTINATION ${CMAKE_CURRENT_LIST_DIR})
            else()
                cmake_path(ABSOLUTE_PATH o3de_install_directory_DESTINATION BASE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
            endif()
            # take out the last directory since install asks for the destination of the folder, without including the fodler itself
            cmake_path(GET o3de_install_directory_DESTINATION PARENT_PATH o3de_install_directory_DESTINATION)
            cmake_path(RELATIVE_PATH o3de_install_directory_DESTINATION BASE_DIRECTORY ${O3DE_ENGINE_PATH})       
        endif()

        unset(exclude_patterns)
        if(o3de_install_directory_EXCLUDE_PATTERNS)
            foreach(exclude_pattern ${o3de_install_directory_EXCLUDE_PATTERNS})
                list(APPEND exclude_patterns PATTERN ${exclude_pattern} EXCLUDE)
            endforeach()
        endif()
        
        if(NOT o3de_install_directory_VERBATIM)
            # Exclude cmake since that has to be generated
            list(APPEND exclude_patterns PATTERN CMakeLists.txt EXCLUDE)
            list(APPEND exclude_patterns PATTERN *.cmake EXCLUDE)

            # Exclude python-related things that dont need to be installed
            list(APPEND exclude_patterns PATTERN __pycache__ EXCLUDE)
            list(APPEND exclude_patterns PATTERN *.egg-info EXCLUDE)
        endif()

        o3de_install(DIRECTORY ${directory}
            DESTINATION ${o3de_install_directory_DESTINATION}
            COMPONENT ${o3de_install_directory_COMPONENT}
            ${exclude_patterns}
        )

    endforeach()

endfunction()

#! o3de_install_files: specifies files to be copied to the install layout at install time
#
# \arg:FILES files to install
# \arg:DESTINATION destination to install the directory to (relative to CMAKE_PREFIX_PATH)
# \arg:PROGRAMS (optional) indicates if the files are programs that should be installed with EXECUTE permissions
#
# \notes: 
#  - refer to cmake's install(FILES/PROGRAMS documentation for more information
#
function(o3de_install_files)

    if(NOT O3DE_INSTALL_ENABLED)
        return()
    endif()

    set(options PROGRAMS)
    set(oneValueArgs DESTINATION)
    set(multiValueArgs FILES)

    cmake_parse_arguments(o3de_install_files "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT o3de_install_files_FILES)
        message(FATAL_ERROR "You must provide a list of files to install")
    endif()
    if(NOT o3de_install_files_DESTINATION)
        message(FATAL_ERROR "You must provide a destination to install files to")
    endif()

    unset(files)
    foreach(file ${o3de_install_files_FILES})
        cmake_path(ABSOLUTE_PATH file)
        list(APPEND files ${file})
    endforeach()

    if(o3de_install_files_PROGRAMS)
        set(install_type PROGRAMS)
    else()
        set(install_type FILES)
    endif()

    o3de_install(${install_type} ${files}
        DESTINATION ${o3de_install_files_DESTINATION}
        COMPONENT ${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME} # use the default for the time being
    )

endfunction()

#! o3de_install_run_code: specifies code to be added to the install process (will run at install time)
#
# \notes: 
#  - refer to cmake's install(CODE documentation for more information
#
function(o3de_install_run_code CODE)

    if(NOT O3DE_INSTALL_ENABLED)
        return()
    endif()

    o3de_install(CODE ${CODE}
        COMPONENT ${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME} # use the default for the time being
    )

endfunction()

#! o3de_install_run_script: specifies path to script to be added to the install process (will run at install time)
#
# \notes: 
#  - refer to cmake's install(SCRIPT documentation for more information
#
function(o3de_install_run_script SCRIPT)

    if(NOT O3DE_INSTALL_ENABLED)
        return()
    endif()

    o3de_install(SCRIPT ${SCRIPT}
        COMPONENT ${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME} # use the default for the time being
    )

endfunction()

if(O3DE_INSTALL_ENABLED)
    include(${O3DE_ENGINE_CMAKE_PAL_PATH}/Install_${O3DE_PAL_PLATFORM_WART}.cmake)
endif()
