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

o3de_pal_path_object_json(${O3DE_ENGINE_JSON_PATH} ${O3DE_ENGINE_PATH}/Code/Framework/AzToolsFramework/Platform/${O3DE_PAL_PLATFORM_NAME} pal_code_framework_aztoolsframework_path)
#set(common_code_framework_aztoolsframework_path ${O3DE_ENGINE_PATH}/Code/Framework/AzToolsFramework/Platform/Common)

o3de_add_target(
    NAME AzToolsFramework STATIC
    NAMESPACE AZ
    AUTOMOC
    AUTOUIC
    AUTORCC
    FILES_CMAKE
        AzToolsFramework/aztoolsframework_files.cmake
        AzToolsFramework/aztoolsframework_${O3DE_PAL_PLATFORM_WART}_files.cmake
        ${pal_code_framework_aztoolsframework_path}/platform_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${pal_code_framework_aztoolsframework_path}/platform_${O3DE_PAL_PLATFORM_WART}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            .
            AzToolsFramework
            ${pal_code_framework_aztoolsframework_path}
    COMPILE_DEFINITIONS
        PRIVATE
            $<$<CONFIG:debug>:ENABLE_UNDOCACHE_CONSISTENCY_CHECKS>
            O3DE_PYTHON_SITE_PACKAGE_SUBPATH="${O3DE_PYTHON_VENV_SITE_PACKAGES}"
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::SQLite
            AZ::AzCore
        PUBLIC
            3rdParty::Qt::Core
            3rdParty::Qt::Gui
            3rdParty::Qt::Widgets
            AZ::AzFramework
            AZ::AzFramework.NativeUI
            AZ::AzQtComponents
)


################################################################################
# Tests
################################################################################
if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)

    o3de_add_target(
        NAME AzToolsFrameworkTestCommon STATIC
        NAMESPACE AZ
        AUTOMOC
        FILES_CMAKE
            AzToolsFramework/aztoolsframeworktestcommon_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                .
        BUILD_DEPENDENCIES
            PUBLIC
                AZ::AzTestShared
            PRIVATE
                3rdParty::Qt::Test
                3rdParty::GoogleBenchmark
                AZ::AzToolsFramework
                AZ::AzTest
    )

    o3de_add_target(
        NAME AzToolsFramework.Tests ${O3DE_PAL_TRAIT_TEST_TARGET_TYPE}
        NAMESPACE AZ
        AUTOMOC
        FILES_CMAKE
            Tests/aztoolsframeworktests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Tests
        COMPILE_DEFINITIONS
            PRIVATE
                O3DE_PYTHON_SITE_PACKAGE_SUBPATH="${O3DE_PYTHON_VENV_SITE_PACKAGES}"
        BUILD_DEPENDENCIES
            PUBLIC
                AZ::AzTestShared
            PRIVATE
                3rdParty::Qt::Test
                AZ::AzFrameworkTestShared
                AZ::AzToolsFramework
                AZ::AzToolsFrameworkTestCommon
                AZ::AzManipulatorTestFramework.Static
                AZ::AzCoreTestCommon
                AZ::AzTest
                AZ::AzQtComponents
        RUNTIME_DEPENDENCIES
            3rdParty::Qt::Test
    )
    o3de_add_googletest(
        NAME AZ::AzToolsFramework.Tests
        LABELS REQUIRES_tiaf
    )
    o3de_add_googlebenchmark(
        NAME AZ::AzToolsFramework.Benchmarks
        TARGET AZ::AzToolsFramework.Tests
    )
endif()
