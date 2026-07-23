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

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Framework/AzQtComponents/Platform/${O3DE_PAL_PLATFORM_NAME} pal_core_framework_azqtcomponents_path)
# The per-platform source file list lives in the nested AzQtComponents/Platform dir
o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Framework/AzQtComponents/AzQtComponents/Platform/${O3DE_PAL_PLATFORM_NAME} pal_nested_azqtcomponents_path)
#set(common_core_framework_azqtcomponents_path ${O3DE_ENGINE_PATH}/Code/Framework/AzQtComponents/Platform/Common)

o3de_add_target(
    NAME AzQtComponents SHARED
    NAMESPACE AZ
    AUTOMOC
    AUTOUIC
    AUTORCC
    FILES_CMAKE
        AzQtComponents/azqtcomponents_files.cmake
        ${pal_nested_azqtcomponents_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_core_framework_azqtcomponents_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            AzQtComponents
        PUBLIC
            .
            ${pal_core_framework_azqtcomponents_path}
    COMPILE_DEFINITIONS
        PRIVATE
            AZ_QT_COMPONENTS_EXPORT_SYMBOLS
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Core
            3rdParty::Qt::Gui
            AZ::AzFramework
        PUBLIC
            3rdParty::Qt::Widgets
            3rdParty::Qt::Svg
            3rdParty::Qt::SvgWidgets
            3rdParty::Qt::Xml
            AZ::AzCore
)

o3de_add_target(
    NAME O3DEQtControlGallery APPLICATION
    NAMESPACE AZ
    AUTOMOC
    AUTOUIC
    FILES_CMAKE
        AzQtComponents/azqtcomponents_gallery_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            .
            AzQtComponents
            AzQtComponents/Gallery
            ${pal_core_framework_azqtcomponents_path}
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Svg
            3rdParty::Qt::Widgets
            AZ::AzQtComponents
            AZ::AzToolsFramework
)

o3de_add_target(
    NAME ReflectedPropertyEditorStandalone APPLICATION
    NAMESPACE AZ
    FILES_CMAKE
        AzQtComponents/azqtcomponents_rpestandalone_files.cmake
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Widgets
            AZ::AzToolsFramework
)

o3de_add_target(
    NAME DPEDebugViewStandalone APPLICATION
    NAMESPACE AZ
    FILES_CMAKE
        AzQtComponents/azqtcomponents_debugviewstandalone_files.cmake
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Widgets
            AZ::AzToolsFramework
            AZ::AzQtComponents
        PUBLIC
            AUTOMOC
)

################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_add_target(
        NAME AzQtComponents.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        FILES_CMAKE
            AzQtComponents/azqtcomponents_testing_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
                AzQtComponents
                ${pal_core_framework_azqtcomponents_path}
        BUILD_DEPENDENCIES
            PRIVATE
                AZ::AzQtComponents
                AZ::AzTest
    )
    o3de_add_googletest(
        NAME AZ::AzQtComponents.Tests
        LABELS REQUIRES_tiaf
    )
endif()
