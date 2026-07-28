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

# This will set python_package_name to whatever the package 'Python' is associated with
o3de_get_package_association(Python python_package_name)
if (NOT python_package_name)
    set(python_package_name "python-no-package-assocation-found")
    message(WARNING "Python was not found in the package assocation list.  Did someone call o3de_associate_package(xxxxxxx Python) ?")
endif()


o3de_add_target(
    NAME ProjectManager.Static STATIC
    NAMESPACE AZ
    AUTOMOC
    FILES_CMAKE
        project_manager_files.cmake
        Platform/${O3DE_PAL_PLATFORM_NAME}/PAL_${O3DE_PAL_PLATFORM_WART}_files.cmake
    PLATFORM_INCLUDE_FILES
        Platform/${O3DE_PAL_PLATFORM_NAME}/PAL_${O3DE_PAL_PLATFORM_WART}.cmake
        Platform/Common/${O3DE_PAL_TRAIT_COMPILER_ID}/projectmanager_${O3DE_PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    COMPILE_DEFINITIONS
        PRIVATE
            PY_PACKAGE="${python_package_name}" 
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
            Platform/${O3DE_PAL_PLATFORM_NAME}
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Core
            3rdParty::Qt::Concurrent
            3rdParty::Qt::Widgets
            3rdParty::Python
            3rdParty::pybind11
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
)

if(O3DE_PAL_TRAIT_BUILD_EXTERNAL_CRASH_HANDLER_SUPPORTED)
    ly_target_link_libraries(ProjectManager.Static PRIVATE AZ::ToolsCrashHandler)
endif()

o3de_add_target(
    NAME ProjectManager APPLICATION
    OUTPUT_NAME o3de
    NAMESPACE AZ
    AUTORCC
    FILES_CMAKE
        project_manager_app_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            Source
    BUILD_DEPENDENCIES
        PRIVATE
            3rdParty::Qt::Core
            3rdParty::Qt::Concurrent
            3rdParty::Qt::Widgets
            3rdParty::Python
            3rdParty::pybind11
            AZ::AzCore
            AZ::AzFramework
            AZ::AzQtComponents
            AZ::AzToolsFramework
            AZ::ProjectManager.Static
)

if(O3DE_PAL_TRAIT_BUILD_TESTS_SUPPORTED)
    o3de_add_target(
        NAME ProjectManager.Tests EXECUTABLE
        NAMESPACE AZ
        FILES_CMAKE
            project_manager_tests_files.cmake
            Platform/${O3DE_PAL_PLATFORM_NAME}/PAL_${O3DE_PAL_PLATFORM_WART}_tests_files.cmake
        INCLUDE_DIRECTORIES
            PRIVATE
                Source
                Platform/${O3DE_PAL_PLATFORM_NAME}
        BUILD_DEPENDENCIES
            PRIVATE
                3rdParty::Qt::Core
                3rdParty::Qt::Concurrent
                3rdParty::Qt::Widgets
                3rdParty::Python
                3rdParty::pybind11
                AZ::AzTest
                AZ::AzFramework
                AZ::AzFrameworkTestShared
                AZ::AzQtComponents
                AZ::ProjectManager.Static
                AZ::AzToolsFramework
    )

    o3de_add_googletest(
        NAME AZ::ProjectManager.Tests
        LABELS REQUIRES_tiaf
        TEST_COMMAND $<TARGET_FILE:AZ::ProjectManager.Tests> --unittest
    )

endif()
