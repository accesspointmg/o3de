#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

if(NOT O3DE_PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

o3de_add_target(
    NAME FFMPEGPlugin MODULE
    NAMESPACE Legacy
    OUTPUT_SUBDIRECTORY EditorPlugins
    FILES_CMAKE
        ffmpegplugin_files.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            PLUGIN_EXPORTS
    INCLUDE_DIRECTORIES
        PUBLIC
            .
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Core
            AZ::AzCore
            Legacy::CryCommon
            Legacy::EditorLib
)

o3de_add_dependencies(Editor FFMPEGPlugin)
set_property(GLOBAL APPEND PROPERTY O3DE_EDITOR_PLUGINS $<TARGET_FILE_NAME:Legacy::FFMPEGPlugin>)
