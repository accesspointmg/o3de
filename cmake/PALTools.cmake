#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# PlatformTools enables to deal with tools that perform functionality cross-platform
# For example, the AssetProcessor can generate assets for other platforms. For the
# asset processor to be able to provide that, it requires to have the functionality enabled.
# This cmake file provides an entry point to discover variables that will allow to enable
# the different platforms and variables that can be passed to enable those platforms to the
# code.

# Discover all the platforms that are available

#set(O3DE_PAL_TOOLS_DEFINES)
#file(GLOB pal_tools_files "cmake/Platform/*/PALTools_*.cmake")
#foreach(pal_tools_file ${pal_tools_files})
#    include(${pal_tools_file})
#endforeach()
#endforeach()

#endif()
#o3de_set(O3DE_PAL_TOOLS_DEFINES ${O3DE_PAL_TOOLS_DEFINES})

# Include files to the CMakeFiles project
#foreach(enabled_platform ${O3DE_PAL_TOOLS_ENABLED})
#    string(TOLOWER ${enabled_platform} enabled_platform_lowercase)
#    o3de_pal_ dir(pal_dir ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Platform/${enabled_platform})
#    o3de_append_cmake_file_list_to_ALLFILES(${pal_dir}/pal_tools_${enabled_platform_lowercase}_files.cmake)
#endforeach()

#function(o3de_get_pal_tool_dirs out_list pal_path)
#    set(pal_paths "")
#    foreach(platform ${O3DE_PAL_TOOLS_ENABLED})
#        o3de_pal_path(${pal_path}/${platform} pal_path)
#        list(APPEND pal_paths ${pal_path})
#    endforeach()
#    set(${out_list} ${pal_paths} PARENT_SCOPE)
#endfunction()
