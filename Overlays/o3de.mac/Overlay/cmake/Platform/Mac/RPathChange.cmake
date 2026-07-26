#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT ${CMAKE_ARGC} EQUAL 6)
    message(FATAL_ERROR "RPathChange script called with the wrong number of arguments")
endif()

find_program(O3DE_INSTALL_NAME_TOOL install_name_tool)
if (NOT O3DE_INSTALL_NAME_TOOL)
    message(FATAL_ERROR "Unable to locate 'install_name_tool'")
endif()

execute_process(COMMAND
    ${O3DE_INSTALL_NAME_TOOL} -rpath ${CMAKE_ARGV4} ${CMAKE_ARGV5} ${CMAKE_ARGV3}
    OUTPUT_QUIET    # in case we already run it
    ERROR_QUIET     # in case we already run it
)
