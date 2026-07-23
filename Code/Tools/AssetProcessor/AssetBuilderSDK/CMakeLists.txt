#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(pal_tool_paths "")
set(pal_tool_files "")
foreach(enabled_platform ${O3DE_PAL_TOOLS_ENABLED})
    o3de_pal_platform_name_wart(${enabled_platform} pal_wart)
    o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/AssetProcessor/AssetBuilderSDK/Platform/${enabled_platform} pal_tool_path)
    list(APPEND pal_tool_paths ${pal_tool_path})
    list(APPEND pal_tool_files ${pal_tool_path}/assetbuildersdk_${pal_wart}_files.cmake)
endforeach()

o3de_add_target(
    NAME AssetBuilderSDK STATIC
    NAMESPACE AZ
    FILES_CMAKE
        assetbuilder_files.cmake
        ${pal_tool_files}
    INCLUDE_DIRECTORIES
        PUBLIC
            .
        PRIVATE
            ${pal_tool_paths}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
        PUBLIC
            AZ::AzFramework
            AZ::AzToolsFramework
            3rdParty::xxhash
)
o3de_add_source_properties(
    SOURCES AssetBuilderSDK/AssetBuilderSDK.cpp
    PROPERTY COMPILE_DEFINITIONS 
    VALUES ${O3DE_PAL_TOOLS_DEFINES}
)
