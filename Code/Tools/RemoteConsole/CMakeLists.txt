#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Tools/RemoteConsole/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_tools_remoteconsole_source_path)
#set(common_code_tools_remoteconsole_source_path ${O3DE_ENGINE_PATH}/Code/Tools/RemoteConsole/Platform/Common)

o3de_add_target(
    NAME RemoteConsoleCore STATIC
    NAMESPACE Legacy
    FILES_CMAKE
        Core/remoteconsolecore_files.cmake
        ${pal_code_tools_remoteconsole_source_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Core
            ${pal_code_tools_remoteconsole_source_path}
    BUILD_DEPENDENCIES
        PRIVATE
            AZ::AzCore
            AZ::AzFramework
            Legacy::CryCommon
)
