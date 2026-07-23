#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# o3de_target_include_system_directories: adds a system include to the target.
# This allows for platform-specific handling of how system includes are added
# to the target. This common implementation just calls
#
#     target_include_directories(<TARGET> SYSTEM <ARGS>)
#
# \arg:TARGET name of the target
# All other unrecognized arguments are passed unchanged to
# target_include_directories
#
function(o3de_target_include_system_directories)

    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs)

    cmake_parse_arguments(o3de_target_include_system_directories "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT o3de_target_include_system_directories_TARGET)
        message(FATAL_ERROR "Target not provided")
    endif()

    target_compile_options(${o3de_target_include_system_directories_TARGET}
        INTERFACE
            ${O3DE_CXX_SYSTEM_INCLUDE_CONFIGURATION_FLAG}
    )

    target_include_directories(${o3de_target_include_system_directories_TARGET} SYSTEM ${o3de_target_include_system_directories_UNPARSED_ARGUMENTS})

endfunction()
