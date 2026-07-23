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
    NAME EditorAssetImporter MODULE
    NAMESPACE Legacy
    OUTPUT_SUBDIRECTORY EditorPlugins
    AUTOMOC
    AUTOUIC
    FILES_CMAKE
        editorassetimporter_files.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            PLUGIN_EXPORTS
    INCLUDE_DIRECTORIES
        PUBLIC
            .
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Core
            3rdParty::Qt::Widgets
            AZ::AzCore
            AZ::AzQtComponents
            AZ::AzToolsFramework
            AZ::SceneCore
            AZ::SceneUI
            AZ::SceneData
            Legacy::CryCommon
            Legacy::EditorLib
            Legacy::EditorCommon
)

o3de_add_dependencies(Editor EditorAssetImporter)
set_property(GLOBAL APPEND PROPERTY O3DE_EDITOR_PLUGINS $<TARGET_FILE_NAME:Legacy::EditorAssetImporter>)
